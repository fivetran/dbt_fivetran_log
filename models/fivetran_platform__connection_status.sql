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

connection_log as (
    select 
        *,
        sum( case when event_subtype in ('sync_start') then 1 else 0 end) over ( partition by connection_id 
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
        -- whole reason is "We have rescheduled the connection to force flush data from the forward sync into your destination. This is intended behavior and means that the connection is working as expected."
),

schema_changes as (

    select
        connection_id,
        count(*) as number_of_schema_changes_last_month

    from {{ ref('stg_fivetran_platform__log') }}

    where 
        {{ dbt.datediff('created_at', dbt.current_timestamp(), 'day') }} <= 30
        and event_subtype in ('create_table', 'alter_table', 'create_schema', 'change_schema_config')

    group by connection_id

),

connection as (

    select *
    from {{ ref('stg_fivetran_platform__connection') }}

),

destination as (

    select * 
    from {{ ref('stg_fivetran_platform__destination') }}
),

connection_metrics as (

    select
        connection.connection_id,
        connection.connection_name,
        connection.connector_type,
        connection.destination_id,
        connection.is_paused,
        connection.set_up_at,
        connection.is_deleted,
        max(case when connection_log.event_subtype = 'sync_start' then connection_log.created_at else null end) as last_sync_started_at,

        max(case when connection_log.event_subtype = 'sync_end' 
            then connection_log.created_at else null end) as last_sync_completed_at,

        max(case when connection_log.event_subtype in ('status', 'sync_end')
                and connection_log.log_status = 'SUCCESSFUL'
            then connection_log.created_at else null end) as last_successful_sync_completed_at,


        max(case when connection_log.event_subtype = 'sync_end' 
            then connection_log.sync_batch_id else null end) as last_sync_batch_id,

        max(case when connection_log.event_subtype in ('status', 'sync_end')
                and connection_log.log_status = 'RESCHEDULED'
                and connection_log.log_reason like '%intended behavior%'
            then connection_log.created_at else null end) as last_priority_first_sync_completed_at,
                

        max(case when connection_log.event_type = 'SEVERE' then connection_log.created_at else null end) as last_error_at,

        max(case when connection_log.event_type = 'SEVERE' then connection_log.sync_batch_id else null end) as last_error_batch,
        max(case when event_type = 'WARNING' then connection_log.created_at else null end) as last_warning_at

    from connection 
    left join connection_log 
        on connection_log.connection_id = connection.connection_id
    group by connection.connection_id, connection.connection_name, connection.connector_type, connection.destination_id, connection.is_paused, connection.set_up_at, connection.is_deleted
),

connection_health_status as (

    select
        *,
        case 
            -- connection is deleted
            when is_deleted {{ ' = 1' if target.type == 'sqlserver' }} then 'deleted'

            -- connection is paused
            when is_paused {{ ' = 1' if target.type == 'sqlserver' }} then 'paused'

            -- a sync has never been attempted
            when last_sync_started_at is null then 'incomplete'

            -- a priority-first sync has occurred, but a normal sync has not
            when last_priority_first_sync_completed_at is not null and last_sync_completed_at is null then 'priority first sync'

            -- a priority sync has occurred more recently than a normal one (may occurr if the connection has been paused and resumed)
            when last_priority_first_sync_completed_at > last_sync_completed_at then 'priority first sync'

            -- a sync has been attempted, but not completed, and it's not due to errors. also a priority-first sync hasn't
            when last_sync_completed_at is null and last_error_at is null then 'initial sync in progress'

            -- the last attempted sync had an error
            when last_sync_batch_id = last_error_batch then 'broken'

            -- there's never been a successful sync and there have been errors
            when last_sync_completed_at is null and last_error_at is not null then 'broken'

        else 'connected' end as connection_health

    from connection_metrics
),

-- Joining with log to grab pertinent error/warning messagees
connection_recent_logs as (

    select 
        connection_health_status.connection_id,
        connection_health_status.connection_name,
        connection_health_status.connector_type,
        connection_health_status.destination_id,
        connection_health_status.connection_health,
        connection_health_status.last_successful_sync_completed_at,
        connection_health_status.last_sync_started_at,
        connection_health_status.last_sync_completed_at,
        connection_health_status.set_up_at,
        connection_log.event_subtype,
        connection_log.event_type,
        connection_log.message_data

    from connection_health_status 
    left join connection_log 
        on connection_log.connection_id = connection_health_status.connection_id
        -- limiting relevance to since the last successful sync completion (if there has been one)
        and connection_log.created_at > coalesce(connection_health_status.last_sync_completed_at, connection_health_status.last_priority_first_sync_completed_at, '2000-01-01') 
        -- only looking at errors and warnings (excluding syncs - both normal and priority first)
        and connection_log.event_type != 'INFO' 
        -- need to explicitly avoid priority first statuses because they are of event_type WARNING
        and not (connection_log.event_subtype = 'status' 
            and connection_log.log_status = 'RESCHEDULED'
            and connection_log.log_reason like '%intended behavior%')

    group by -- remove duplicates, need explicit group by for SQL Server
        connection_health_status.connection_id,
        connection_health_status.connection_name,
        connection_health_status.connector_type,
        connection_health_status.destination_id,
        connection_health_status.connection_health,
        connection_health_status.last_successful_sync_completed_at,
        connection_health_status.last_sync_started_at,
        connection_health_status.last_sync_completed_at,
        connection_health_status.set_up_at,
        connection_log.event_subtype,
        connection_log.event_type,
        connection_log.message_data
),

final as (

    select
        connection_recent_logs.connection_id,
        connection_recent_logs.connection_name,
        connection_recent_logs.connector_type,
        connection_recent_logs.destination_id,
        destination.destination_name,
        connection_recent_logs.connection_health,
        connection_recent_logs.last_successful_sync_completed_at,
        connection_recent_logs.last_sync_started_at,
        connection_recent_logs.last_sync_completed_at,
        connection_recent_logs.set_up_at,
        coalesce(schema_changes.number_of_schema_changes_last_month, 0) as number_of_schema_changes_last_month,
        count(case when connection_recent_logs.event_type = 'SEVERE' then connection_recent_logs.message_data else null end) as number_errors_since_last_completed_sync,
        count(case when connection_recent_logs.event_type = 'WARNING' then connection_recent_logs.message_data else null end) as number_warnings_since_last_completed_sync

    from connection_recent_logs
    left join schema_changes 
        on connection_recent_logs.connection_id = schema_changes.connection_id 

    join destination on destination.destination_id = connection_recent_logs.destination_id

    -- need explicit group bys for SQL Server
    group by 
        connection_recent_logs.connection_id, 
        connection_recent_logs.connection_name, 
        connection_recent_logs.connector_type, 
        connection_recent_logs.destination_id, 
        destination.destination_name, 
        connection_recent_logs.connection_health, 
        connection_recent_logs.last_successful_sync_completed_at, 
        connection_recent_logs.last_sync_started_at, 
        connection_recent_logs.last_sync_completed_at, 
        connection_recent_logs.set_up_at, 
        schema_changes.number_of_schema_changes_last_month
)

select * 
from final