-- depends_on: {{ var('connector') }}

with connector as (
    
    select * 
    from {{ ref('fivetran_platform__connector_status') }}
),

-- grab api calls, schema changes, and record modifications
log_events as (

    select 
        connector_id,
        cast( {{ dbt.date_trunc('day', 'created_at') }} as date) as date_day,
        case 
            when event_subtype in ('create_table', 'alter_table', 'create_schema', 'change_schema_config') then 'schema_change' 
            else event_subtype end as event_subtype,

        sum(case when event_subtype = 'records_modified' then cast( {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['count']) }} as {{ dbt.type_bigint()}} )
        else 1 end) as count_events 

    from {{ ref('stg_fivetran_platform__log') }}

    where event_subtype in ('api_call', 
                            'records_modified', 
                            'create_table', 'alter_table', 'create_schema', 'change_schema_config') -- all schema changes
                            
        and connector_id is not null

    group by connector_id, cast( {{ dbt.date_trunc('day', 'created_at') }} as date), event_subtype
),

pivot_out_events as (

    select
        connector_id,
        date_day,
        max(case when event_subtype = 'api_call' then count_events else 0 end) as count_api_calls,
        max(case when event_subtype = 'records_modified' then count_events else 0 end) as count_record_modifications,
        max(case when event_subtype = 'schema_change' then count_events else 0 end) as count_schema_changes

    from log_events
    group by connector_id, date_day
), 

connector_event_counts as (

    select
        pivot_out_events.date_day,
        pivot_out_events.count_api_calls,
        pivot_out_events.count_record_modifications,
        pivot_out_events.count_schema_changes,
        connector.connector_name,
        connector.connector_id,
        connector.connector_type,
        connector.destination_name,
        connector.destination_id,
        connector.set_up_at
    from
    connector left join pivot_out_events 
        on pivot_out_events.connector_id = connector.connector_id
),

spine as (

    {% if execute %}
    {% set first_date_query %}
        select  min( signed_up ) as min_date from {{ var('connector') }}
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
            end_date = dbt.dateadd("week", 1, dbt.date_trunc('day', dbt.current_timestamp_backcompat() if target.type != 'sqlserver' else dbt.current_timestamp())) 
            ) 
        }} 
    ) as date_spine
),

connector_event_history as (

    select
        spine.date_day,
        connector_event_counts.connector_name,
        connector_event_counts.connector_id,
        connector_event_counts.connector_type,
        connector_event_counts.destination_name,
        connector_event_counts.destination_id,
        max(case 
            when spine.date_day = connector_event_counts.date_day then connector_event_counts.count_api_calls
            else 0
        end) as count_api_calls,
        max(case 
            when spine.date_day = connector_event_counts.date_day then connector_event_counts.count_record_modifications
            else 0
        end) as count_record_modifications,
        max(case 
            when spine.date_day = connector_event_counts.date_day then connector_event_counts.count_schema_changes
            else 0
        end) as count_schema_changes
    from
    spine join connector_event_counts
        on spine.date_day  >= cast({{ dbt.date_trunc('day', 'cast(connector_event_counts.set_up_at as date)') }} as date)

    group by spine.date_day, connector_name, connector_id, connector_type, destination_name, destination_id
),

-- now rejoin spine to get a complete calendar
join_event_history as (
    
    select
        spine.date_day,
        connector_event_history.connector_name,
        connector_event_history.connector_id,
        connector_event_history.connector_type,
        connector_event_history.destination_name,
        connector_event_history.destination_id,
        max(connector_event_history.count_api_calls) as count_api_calls,
        max(connector_event_history.count_record_modifications) as count_record_modifications,
        max(connector_event_history.count_schema_changes) as count_schema_changes

    from
    spine left join connector_event_history
        on spine.date_day = connector_event_history.date_day

    group by spine.date_day, connector_name, connector_id, connector_type, destination_name, destination_id
),

final as (

    select *
    from join_event_history

    where date_day <= cast({{ dbt.current_timestamp_backcompat() if target.type != 'sqlserver' else dbt.current_timestamp() }} as date)
)

select *
from final