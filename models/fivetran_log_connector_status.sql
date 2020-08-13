with connector_log as (

    select *
    from {{ ref('stg_fivetran_log_log') }}

    -- only looking at errors, warnings, and syncs here
    where event_type = 'SEVERE'
        or event_type = 'WARNING'
        or event_subtype like 'sync%'

),

schema_changes as (

    select
        connector_name,
        destination_database,
        count(*) as number_of_schema_changes_last_month

    from {{ ref('stg_fivetran_log_log') }}

    where 
        {{ dbt_utils.datediff('created_at', dbt_utils.current_timestamp(), 'day') }} <= 30
        and event_subtype in ('create_table', 'alter_table', 'create_schema', 'change_schema_config')

    group by 1,2

),

connector as (

    select *
    from {{ ref('stg_fivetran_log_connector') }}

),

destination as (

    select * 
    from {{ ref('stg_fivetran_log_destination') }}
),

connector_metrics as (

    select
        connector.connector_id,
        connector.connector_name,
        connector.connector_type,
        connector.destination_id,
        connector.destination_database,
        connector.is_paused,
        connector.set_up_at,
        max(case when connector_log.event_subtype = 'sync_start' then connector_log.created_at else null end) as last_synced_at,
        max(case when connector_log.event_subtype = 'sync_end' then connector_log.created_at else null end) as last_sync_completed_at,
        max(case when connector_log.event_type = 'SEVERE' then connector_log.created_at else null end) as last_error_at,
        max(case when event_type = 'WARNING' then connector_log.created_at else null end) as last_warning_at

    from connector_log 
        right join connector on connector_log.connector_name = connector.connector_name
        and connector_log.destination_database = connector.destination_database
    group by 1,2,3,4,5,6,7

),

connector_health as (

    select
        *,
        case 
            when last_error_at > last_sync_completed_at or last_sync_completed_at is null then 'broken'
        else 'connected' end as connector_health,

        case 
        when is_paused then 'paused'
        when last_error_at > last_synced_at then 'sync failed'
        when last_synced_at > last_sync_completed_at and last_warning_at > last_synced_at then 'in progress, see warnings'
        when last_synced_at > last_sync_completed_at then 'in progress'
        else 'running on schedule' end as data_sync_status

    from connector_metrics
),

-- Joining with log to grab pertinent error/warning messagees
connector_recent_logs as (

    select 
        connector_health.connector_id,
        connector_health.connector_name,
        connector_health.connector_type,
        connector_health.destination_id,
        connector_health.destination_database,
        connector_health.connector_health,
        connector_health.data_sync_status,
        connector_health.last_synced_at,
        connector_health.set_up_at,
        connector_log.event_subtype,
        connector_log.event_type,
        connector_log.message_data

    from connector_health 
    left join connector_log 
        on connector_log.connector_name = connector_health.connector_name 
        and connector_log.destination_database = connector_health.destination_database

        -- limiting relevance to since the last successful sync completion (if there has been one)
        and connector_log.created_at > coalesce(connector_health.last_sync_completed_at, '2000-01-01') 

        -- only looking at erors and warnings (excluding syncs)
        and connector_log.event_type != 'INFO'  

    group by 1,2,3,4,5,6,7,8,9,10,11,12 -- de-duping error messages
    

),

final as (

    select
        connector_recent_logs.connector_id,
        connector_recent_logs.connector_name,
        connector_recent_logs.connector_type,
        connector_recent_logs.destination_id,
        destination.destination_name,
        connector_recent_logs.destination_database,
        connector_recent_logs.connector_health,
        connector_recent_logs.data_sync_status,
        connector_recent_logs.last_synced_at,
        connector_recent_logs.set_up_at,
        coalesce(schema_changes.number_of_schema_changes_last_month, 0) as number_of_schema_changes_last_month,
        
        {{ string_agg("case when connector_recent_logs.event_type = 'SEVERE' then connector_recent_logs.message_data else null end", "'\\n'") }} as errors_since_last_completed_sync,
        {{ string_agg("case when connector_recent_logs.event_type = 'WARNING' then connector_recent_logs.message_data else null end", "'\\n'") }} as warnings_since_last_completed_sync
        

    from connector_recent_logs
    left join schema_changes 
        on connector_recent_logs.connector_name = schema_changes.connector_name 
        and connector_recent_logs.destination_database = schema_changes.destination_database

    join destination on destination.destination_id = connector_recent_logs.destination_id
    group by 1,2,3,4,5,6,7,8,9,10,11
)

select * from final