with transformation_removal as (

    select 
        *,
        case when event_subtype in ('status', 'sync_end')
            then message_data
            else null 
        end as filtered_message_data
    from {{ ref('stg_fivetran_platform__log') }}
    where transformation_id is null
),

parse_json as (
    select
        *,
        {{ fivetran_log.fivetran_log_json_parse(string="filtered_message_data", string_path=["status"]) }} as log_status,
        {{ fivetran_log.fivetran_log_json_parse(string="filtered_message_data", string_path=["reason"]) }} as log_reason
    from transformation_removal
),

connector_log as (
    select 
        *,
        sum( case when event_subtype in ('sync_start') then 1 else 0 end) over ( partition by connector_id 
            order by created_at rows unbounded preceding) as sync_batch_id
    from parse_json
    -- only looking at errors, warnings, and syncs here
    where event_type = 'SEVERE'
        or event_type = 'WARNING'
        or event_subtype like 'sync%'
        or (event_subtype = 'status' 
            and log_status = 'RESCHEDULED'
            and log_reason like '%intended behavior%'
            ) -- for priority-first syncs. these should be captured by event_type = 'WARNING' but let's make sure
        or (event_subtype = 'status' 
            and log_status = 'SUCCESSFUL'
        )
        -- whole reason is "We have rescheduled the connector to force flush data from the forward sync into your destination. This is intended behavior and means that the connector is working as expected."
),

schema_changes as (

    select
        connector_id,
        count(*) as number_of_schema_changes_last_month

    from {{ ref('stg_fivetran_platform__log') }}

    where 
        {{ dbt.datediff('created_at', dbt.current_timestamp_backcompat() if target.type != 'sqlserver' else dbt.current_timestamp(), 'day') }} <= 30
        and event_subtype in ('create_table', 'alter_table', 'create_schema', 'change_schema_config')

    group by connector_id

),

connector as (

    select *
    from {{ ref('stg_fivetran_platform__connector') }}

),

destination as (

    select * 
    from {{ ref('stg_fivetran_platform__destination') }}
),

connector_metrics as (

    select
        connector.connector_id,
        connector.connector_name,
        connector.connector_type,
        connector.destination_id,
        connector.is_paused,
        connector.set_up_at,
        connector.is_deleted,
        max(case when connector_log.event_subtype = 'sync_start' then connector_log.created_at else null end) as last_sync_started_at,

        max(case when connector_log.event_subtype = 'sync_end' 
            then connector_log.created_at else null end) as last_sync_completed_at,

        max(case when connector_log.event_subtype in ('status', 'sync_end')
                and connector_log.log_status = 'SUCCESSFUL'
            then connector_log.created_at else null end) as last_successful_sync_completed_at,


        max(case when connector_log.event_subtype = 'sync_end' 
            then connector_log.sync_batch_id else null end) as last_sync_batch_id,

        max(case when connector_log.event_subtype in ('status', 'sync_end')
                and connector_log.log_status = 'RESCHEDULED'
                and connector_log.log_reason like '%intended behavior%'
            then connector_log.created_at else null end) as last_priority_first_sync_completed_at,
                

        max(case when connector_log.event_type = 'SEVERE' then connector_log.created_at else null end) as last_error_at,

        max(case when connector_log.event_type = 'SEVERE' then connector_log.sync_batch_id else null end) as last_error_batch,
        max(case when event_type = 'WARNING' then connector_log.created_at else null end) as last_warning_at

    from connector 
    left join connector_log 
        on connector_log.connector_id = connector.connector_id
    group by connector.connector_id, connector.connector_name, connector.connector_type, connector.destination_id, connector.is_paused, connector.set_up_at, connector.is_deleted
),

connector_health_status as (

    select
        *,
        case 
            -- connector is deleted
            when is_deleted {{ ' = 1' if target.type == 'sqlserver' }} then 'deleted'

            -- connector is paused
            when is_paused {{ ' = 1' if target.type == 'sqlserver' }} then 'paused'

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
        connector_health_status.connector_id,
        connector_health_status.connector_name,
        connector_health_status.connector_type,
        connector_health_status.destination_id,
        connector_health_status.connector_health,
        connector_health_status.last_successful_sync_completed_at,
        connector_health_status.last_sync_started_at,
        connector_health_status.last_sync_completed_at,
        connector_health_status.set_up_at,
        connector_log.event_subtype,
        connector_log.event_type,
        connector_log.message_data

    from connector_health_status 
    left join connector_log 
        on connector_log.connector_id = connector_health_status.connector_id
        -- limiting relevance to since the last successful sync completion (if there has been one)
        and connector_log.created_at > coalesce(connector_health_status.last_sync_completed_at, connector_health_status.last_priority_first_sync_completed_at, '2000-01-01') 
        -- only looking at errors and warnings (excluding syncs - both normal and priority first)
        and connector_log.event_type != 'INFO' 
        -- need to explicitly avoid priority first statuses because they are of event_type WARNING
        and not (connector_log.event_subtype = 'status' 
            and connector_log.log_status = 'RESCHEDULED'
            and connector_log.log_reason like '%intended behavior%')

    group by -- remove duplicates, need explicit group by for SQL Server
        connector_health_status.connector_id,
        connector_health_status.connector_name,
        connector_health_status.connector_type,
        connector_health_status.destination_id,
        connector_health_status.connector_health,
        connector_health_status.last_successful_sync_completed_at,
        connector_health_status.last_sync_started_at,
        connector_health_status.last_sync_completed_at,
        connector_health_status.set_up_at,
        connector_log.event_subtype,
        connector_log.event_type,
        connector_log.message_data
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
        coalesce(schema_changes.number_of_schema_changes_last_month, 0) as number_of_schema_changes_last_month,
        count(case when connector_recent_logs.event_type = 'SEVERE' then connector_recent_logs.message_data else null end) as number_errors_since_last_completed_sync,
        count(case when connector_recent_logs.event_type = 'WARNING' then connector_recent_logs.message_data else null end) as number_warnings_since_last_completed_sync

    from connector_recent_logs
    left join schema_changes 
        on connector_recent_logs.connector_id = schema_changes.connector_id 

    join destination on destination.destination_id = connector_recent_logs.destination_id

    -- need explicit group bys for SQL Server
    group by 
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
        schema_changes.number_of_schema_changes_last_month
)

select * 
from final