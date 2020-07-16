with log as (

    select *
    from {{ ref('stg_fivetran_log_log') }}

    -- ignoring INFO events and transformations
    where event_type = 'ERROR'
        or event_type = 'WARNING'
        or event_subtype like 'sync%'

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
        -- connector_health.is_paused,
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

agg_connector_recent_logs as (

    select
        connector_id,
        connector_name,
        connector_type,
        destination_id,
        connector_status,
        data_sync_status,
        last_synced_at,
        
        {{  string_agg('case when event_type = "ERROR" then message_data else null end', "'\\n'") }} as errors_since_last_completed_sync,
        {{ string_agg('case when event_type = "WARNING" then message_data else null end', "'\\n'") }} as warnings_since_last_completed_sync,


    from connector_recent_logs
    group by 1,2,3,4,5,6,7
)
,

final as (

    select 
        connector_id,
        connector_name,
        connector_type,
        destination_id,
        connector_status,
        data_sync_status,
        last_synced_at
    
    from agg_connector_recent_logs
)

select * from agg_connector_recent_logs