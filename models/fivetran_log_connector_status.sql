with log as (

    select *
    from {{ ref('stg_fivetran_log_log') }}

    -- ignoring INFO events and transformations
    where event_type = 'ERROR'
        or event_type = 'WARNING'
        or event_subtype like 'sync%'

),

schema_changes as (

    select
        connector_id,
        count(*) as number_of_schema_changes

    from {{ ref('stg_fivetran_log_log') }}
    where {{ dbt_utils.datediff('created_at', dbt_utils.current_timestamp(), 'day') }} <= 30
    and event_subtype in ('create_table', 'alter_table', 'create_schema')

    group by 1

),

connector as (

    select *
    from {{ ref('stg_fivetran_log_connector') }}

),

connector_metrics as (

    select
        log.connector_id,
        connector.connector_name,
        connector.connector_type,
        connector.destination_id,
        connector.is_paused,
        max(case when log.event_subtype = 'sync_start' then log.created_at else null end) as last_synced_at,
        max(case when log.event_subtype = 'sync_end' then log.created_at else null end) as last_sync_completed_at,
        max(case when log.event_type = 'ERROR' then log.created_at else null end) as last_error_at,
        max(case when event_type = 'WARNING' then created_at else null end) as last_warning_at

    from log 
        join connector on log.connector_id = connector.connector_name -- todo: change when bug is fixed
    group by 1,2,3,4,5

),

connector_health as (

    select
        *,
        case when last_sync_completed_at > last_error_at or connector_metrics.last_error_at is null then 'connected'
        else 'broken' end as connector_status,

        case 
        when is_paused then 'paused'
        when last_error_at > last_synced_at then 'sync failed'
        when last_synced_at > last_sync_completed_at and last_warning_at > last_synced_at then 'in progress, see warnings'
        when last_synced_at > last_sync_completed_at then 'in progress'
        else 'running on schedule' end as data_sync_status

    from connector_metrics
),


connector_recent_logs as (

    select 
        connector_health.connector_id,
        connector_health.connector_name,
        connector_health.connector_type,
        connector_health.destination_id,
        connector_health.connector_status,
        connector_health.data_sync_status,
        connector_health.last_synced_at,
        log.event_subtype,
        log.event_type,
        log.message_data

    from connector_health left join log 
        on log.connector_id = connector_health.connector_name -- TODO: should actually be connector_id once bug is fixed 
        and log.created_at > connector_health.last_sync_completed_at
        and log.event_type != 'INFO'  -- only looking at erors and warnings

    group by 1,2,3,4,5,6,7,8,9,10 -- getting the distinct error messages
    

),

final as (

    select
        connector_recent_logs.connector_id,
        connector_recent_logs.connector_name,
        connector_recent_logs.connector_type,
        connector_recent_logs.destination_id,
        connector_recent_logs.connector_status,
        connector_recent_logs.data_sync_status,
        connector_recent_logs.last_synced_at,
        coalesce(schema_changes.number_of_schema_changes, 0) as number_of_schema_changes_last_month,
        
        -- need some data with errors/warnings to test.... TODO
        {{ string_agg('case when connector_recent_logs.event_type = "ERROR" then connector_recent_logs.message_data else null end', "'\\n'") }} as errors_since_last_completed_sync,
        {{ string_agg('case when connector_recent_logs.event_type = "WARNING" then connector_recent_logs.message_data else null end', "'\\n'") }} as warnings_since_last_completed_sync
        

    from connector_recent_logs
    left join schema_changes 
        on connector_recent_logs.connector_name = schema_changes.connector_id -- TODO: change when bug is fixed
    group by 1,2,3,4,5,6,7,8
)

select * from final