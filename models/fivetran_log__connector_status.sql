with transformation_removal as (

    select *
    from {{ ref('stg_fivetran_log__log') }}
    where transformation_id is null

),

connector_log as (
    select 
        *,
        sum( case when event_subtype in ('sync_start') then 1 else 0 end) over ( partition by connector_id 
            order by created_at rows unbounded preceding) as sync_batch_id
    from transformation_removal
    -- only looking at errors, warnings, and syncs here
    where event_type = 'SEVERE'
        or event_type = 'WARNING'
        or event_subtype like 'sync%'
        or (event_subtype = 'status' 
            and {{ fivetran_utils.json_parse(string="message_data", string_path=["status"]) }} = 'RESCHEDULED'
            
            and {{ fivetran_utils.json_parse(string="message_data", string_path=["reason"]) }} like '%intended behavior%'
            ) -- for priority-first syncs. these should be captured by event_type = 'WARNING' but let's make sure
        or (event_subtype = 'status' 
            and {{ fivetran_utils.json_parse(string="message_data", string_path=["status"]) }} = 'SUCCESSFUL'
        )
        -- whole reason is "We have rescheduled the connector to force flush data from the forward sync into your destination. This is intended behavior and means that the connector is working as expected."
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

        max(case when connector_log.event_subtype = 'sync_end' 
            then connector_log.created_at else null end) as last_sync_completed_at,

        max(case when connector_log.event_subtype in ('status', 'sync_end')
                and {{ fivetran_utils.json_parse(string="connector_log.message_data", string_path=["status"]) }} ='SUCCESSFUL'
            then connector_log.created_at else null end) as last_successful_sync_completed_at,


        max(case when connector_log.event_subtype = 'sync_end' 
            then connector_log.sync_batch_id else null end) as last_sync_batch_id,

        max(case when connector_log.event_subtype in ('status', 'sync_end')
                and {{ fivetran_utils.json_parse(string="connector_log.message_data", string_path=["status"]) }} ='RESCHEDULED'
                and {{ fivetran_utils.json_parse(string="connector_log.message_data", string_path=["reason"]) }} like '%intended behavior%'
            then connector_log.created_at else null end) as last_priority_first_sync_completed_at,
                

        max(case when connector_log.event_type = 'SEVERE' then connector_log.created_at else null end) as last_error_at,

        max(case when connector_log.event_type = 'SEVERE' then connector_log.sync_batch_id else null end) as last_error_batch,
        max(case when event_type = 'WARNING' then connector_log.created_at else null end) as last_warning_at

    from connector 
    left join connector_log 
        on connector_log.connector_id = connector.connector_id
    {{ dbt_utils.group_by(n=6) }}

),

connector_health as (

    select
        *,
        case 
            -- connector is paused
            when is_paused then 'paused'

            -- a sync has never been attempted
            when last_sync_started_at is null then 'incomplete'

            -- a priority-first sync has occurred, but a normal sync has not
            when last_priority_first_sync_completed_at is not null and last_sync_completed_at is null then 'priority first sync'

            -- a priority sync has occurred more recently than a normal one (may occurr if the connector has been paused and resumed)
            when last_priority_first_sync_completed_at > last_sync_completed_at then 'priority first sync'

            -- a sync has been attempted, but not completed, and it's not due to errors. also a priority-first sync hasn't
            when last_sync_completed_at is null and last_error_at is null then 'initial sync in progress'

            -- the last attempted sync had an error
            when last_sync_batch_id = last_error_batch then 'broken'

            -- there's never been a successful sync and there have been errors
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
        connector_health.last_successful_sync_completed_at,
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
        and connector_log.created_at > coalesce(connector_health.last_sync_completed_at, connector_health.last_priority_first_sync_completed_at, '2000-01-01') 
        -- only looking at errors and warnings (excluding syncs - both normal and priority first)
        and connector_log.event_type != 'INFO' 
        -- need to explicitly avoid priority first statuses because they are of event_type WARNING
        and not (connector_log.event_subtype = 'status' 
            and {{ fivetran_utils.json_parse(string="connector_log.message_data", string_path=["status"]) }} ='RESCHEDULED'
            and {{ fivetran_utils.json_parse(string="connector_log.message_data", string_path=["reason"]) }} like '%intended behavior%')

    {{ dbt_utils.group_by(n=12) }} -- de-duping error messages
    

),

final as (

    select
        connector_recent_logs.connector_id,
        connector_recent_logs.connector_name,
        connector_recent_logs.connector_type,
        connector_recent_logs.destination_id,
        destination.destination_name,
        connector_recent_logs.connector_health,
        connector_recent_logs.last_successful_sync_completed_at,
        connector_recent_logs.last_sync_started_at,
        connector_recent_logs.last_sync_completed_at,
        connector_recent_logs.set_up_at,
        coalesce(schema_changes.number_of_schema_changes_last_month, 0) as number_of_schema_changes_last_month
        
        {% if var('fivetran_log_using_sync_alert_messages', true) %}
        , {{ fivetran_utils.string_agg("distinct case when connector_recent_logs.event_type = 'SEVERE' then connector_recent_logs.message_data else null end", "'\\n'") }} as errors_since_last_completed_sync
        , {{ fivetran_utils.string_agg("distinct case when connector_recent_logs.event_type = 'WARNING' then connector_recent_logs.message_data else null end", "'\\n'") }} as warnings_since_last_completed_sync
        {% endif %}

    from connector_recent_logs
    left join schema_changes 
        on connector_recent_logs.connector_id = schema_changes.connector_id 

    join destination on destination.destination_id = connector_recent_logs.destination_id
    {{ dbt_utils.group_by(n=11) }}
)

select * from final