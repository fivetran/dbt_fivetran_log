-- depends_on: {{ ref('stg_fivetran_platform__connection') }}

with connection as (
    
    select * 
    from {{ ref('fivetran_platform__connection_status') }}
),

-- grab api calls, schema changes, and record modifications

log_events as (

    select 
        connection_id,
        cast( {{ dbt.date_trunc('day', 'created_at') }} as date) as date_day,
        event_subtype,
        replace(message_data, 'totalQueries', 'total_queries') as message_data

    from {{ ref('stg_fivetran_platform__log') }}

    where event_subtype in (
        'api_call', 'extract_summary', 'records_modified', 'create_table', 'alter_table',
        'create_schema', 'change_schema_config') -- all relevant event subtypes
        and connection_id is not null
),

agg_log_events as (

    select 
        connection_id,
        date_day,
        case 
            when event_subtype in ('create_table', 'alter_table', 'create_schema', 'change_schema_config') then 'schema_change' 
            else event_subtype end as event_subtype,

        sum(
            case 
                when event_subtype = 'records_modified' 
                then cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['count']) }} as {{ dbt.type_bigint()}} )
                when event_subtype = 'extract_summary'
                then cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['total_queries']) }} as {{ dbt.type_bigint()}})
                else 1
                end
            ) as count_events

    from log_events
    group by connection_id, date_day, event_subtype
),

pivot_out_events as (

    select
        connection_id,
        date_day,
        max(case when event_subtype = 'api_call' or event_subtype = 'extract_summary' then count_events else 0 end) as count_api_calls,
        max(case when event_subtype = 'records_modified' then count_events else 0 end) as count_record_modifications,
        max(case when event_subtype = 'schema_change' then count_events else 0 end) as count_schema_changes

    from agg_log_events
    group by connection_id, date_day
), 

connection_event_counts as (

    select
        pivot_out_events.date_day,
        pivot_out_events.count_api_calls,
        pivot_out_events.count_record_modifications,
        pivot_out_events.count_schema_changes,
        connection.connection_name,
        connection.connection_id,
        connection.connector_type,
        connection.destination_name,
        connection.destination_id,
        connection.set_up_at
    from
    connection left join pivot_out_events 
        on pivot_out_events.connection_id = connection.connection_id
),

spine as (

    {% if execute and flags.WHICH in ('run', 'build') %}
    {% set first_date_query %}
        select  min( set_up_at ) as min_date from {{ ref('stg_fivetran_platform__connection') }}
    {% endset %}
    {% set first_date = run_query(first_date_query).columns[0][0]|string %}
    
    {% else %} {% set first_date = "2016-01-01" %}
    {% endif %}

    select 
        cast(date_day as date) as date_day
    from (
        {{ fivetran_utils.fivetran_date_spine(
            datepart = "day", 
            start_date =  "cast('" ~ first_date[0:10] ~ "' as date)", 
            end_date = dbt.dateadd("week", 1, dbt.date_trunc('day', dbt.current_timestamp())) 
            ) 
        }} 
    ) as date_spine
),

connection_event_history as (

    select
        spine.date_day,
        connection_event_counts.connection_name,
        connection_event_counts.connection_id,
        connection_event_counts.connector_type,
        connection_event_counts.destination_name,
        connection_event_counts.destination_id,
        max(case 
            when spine.date_day = connection_event_counts.date_day then connection_event_counts.count_api_calls
            else 0
        end) as count_api_calls,
        max(case 
            when spine.date_day = connection_event_counts.date_day then connection_event_counts.count_record_modifications
            else 0
        end) as count_record_modifications,
        max(case 
            when spine.date_day = connection_event_counts.date_day then connection_event_counts.count_schema_changes
            else 0
        end) as count_schema_changes
    from
    spine join connection_event_counts
        on spine.date_day  >= cast({{ dbt.date_trunc('day', 'cast(connection_event_counts.set_up_at as date)') }} as date)

    group by spine.date_day, connection_name, connection_id, connector_type, destination_name, destination_id
),

-- now rejoin spine to get a complete calendar
join_event_history as (
    
    select
        spine.date_day,
        connection_event_history.connection_name,
        connection_event_history.connection_id,
        connection_event_history.connector_type,
        connection_event_history.destination_name,
        connection_event_history.destination_id,
        max(connection_event_history.count_api_calls) as count_api_calls,
        max(connection_event_history.count_record_modifications) as count_record_modifications,
        max(connection_event_history.count_schema_changes) as count_schema_changes

    from
    spine left join connection_event_history
        on spine.date_day = connection_event_history.date_day

    group by spine.date_day, connection_name, connection_id, connector_type, destination_name, destination_id
),

final as (

    select *
    from join_event_history

    where date_day <= cast({{ dbt.current_timestamp() }} as date)
)

select *
from final