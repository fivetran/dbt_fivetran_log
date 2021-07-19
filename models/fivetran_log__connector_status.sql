with connector_log as (

    select *
    from {{ ref('stg_fivetran_log__log') }}

    -- only looking at errors, warnings, and syncs here
    where event_type = 'SEVERE'
        or event_type = 'WARNING'
        or event_subtype like 'sync%'

),

schema_changes as (

    select
        connector_id,
        count(*) as number_of_schema_changes_last_month

    from {{ ref('stg_fivetran_log__log') }}

    where 
        {{ dbt_utils.datediff('created_at', dbt_utils.current_timestamp(), 'day') }} <= 30
        and event_subtype in ('create_table', 'alter_table', 'create_schema', 'change_schema_config')

    group by 1

),

connector as (

    select *
    from {{ ref('stg_fivetran_log__connector') }}

),

destination as (

    select * 
    from {{ ref('stg_fivetran_log__destination') }}
),

connector_metrics as (

    select
        connector.connector_id,
        connector.connector_name,
        connector.connector_type,
        connector.destination_id,
        connector.is_paused,
        connector.set_up_at,
        max(case when connector_log.event_subtype = 'sync_start' then connector_log.created_at else null end) as last_sync_started_at,
        max(case when connector_log.event_subtype = 'sync_end' then connector_log.created_at else null end) as last_sync_completed_at,
        max(case when connector_log.event_type = 'SEVERE' then connector_log.created_at else null end) as last_error_at,
        max(case when event_type = 'WARNING' then connector_log.created_at else null end) as last_warning_at

    from connector 
    left join connector_log 
        on connector_log.connector_id = connector.connector_id
    group by 1,2,3,4,5,6

),

connector_health as (

    select
        *,
        case 
            -- there has not been a sync
            when is_paused then 'paused'
            when last_sync_started_at is null then 'incomplete'
            when last_sync_completed_at is null and last_error_at is null then 'initial sync in progress'

            when last_error_at > last_sync_completed_at then 'broken'
            when last_sync_completed_at is null and last_error_at is not null then 'broken'
        else 'connected' end as connector_health

    from connector_metrics
),

-- Joining with log to grab pertinent error/warning messagees
connector_recent_logs as (

    select 
        connector_health.connector_id,
        connector_health.connector_name,
        connector_health.connector_type,
        connector_health.destination_id,
        connector_health.connector_health,
        connector_health.last_sync_started_at,
        connector_health.last_sync_completed_at,
        connector_health.set_up_at,
        connector_log.event_subtype,
        connector_log.event_type,
        connector_log.message_data

    from connector_health 
    left join connector_log 
        on connector_log.connector_id = connector_health.connector_id
        -- limiting relevance to since the last successful sync completion (if there has been one)
        and connector_log.created_at > coalesce(connector_health.last_sync_completed_at, '2000-01-01') 
        -- only looking at erors and warnings (excluding syncs)
        and connector_log.event_type != 'INFO'  

    group by 1,2,3,4,5,6,7,8,9,10,11 -- de-duping error messages
    

),

final as (

    select
        connector_recent_logs.connector_id,
        connector_recent_logs.connector_name,
        connector_recent_logs.connector_type,
        connector_recent_logs.destination_id,
        destination.destination_name,
        connector_recent_logs.connector_health,
        connector_recent_logs.last_sync_started_at,
        connector_recent_logs.last_sync_completed_at,
        connector_recent_logs.set_up_at,
        coalesce(schema_changes.number_of_schema_changes_last_month, 0) as number_of_schema_changes_last_month
        
        {% if var('fivetran_log_using_sync_alert_messages', true) %}
        , {{ fivetran_utils.string_agg("case when connector_recent_logs.event_type = 'SEVERE' then connector_recent_logs.message_data else null end", "'\\n'") }} as errors_since_last_completed_sync
        , {{ fivetran_utils.string_agg("case when connector_recent_logs.event_type = 'WARNING' then connector_recent_logs.message_data else null end", "'\\n'") }} as warnings_since_last_completed_sync
        {% endif %}

    from connector_recent_logs
    left join schema_changes 
        on connector_recent_logs.connector_id = schema_changes.connector_id 

    join destination on destination.destination_id = connector_recent_logs.destination_id
    {{ dbt_utils.group_by(n=10) }}
)

select * from final