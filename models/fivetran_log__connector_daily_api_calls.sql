with connector as (
    
    select * 
    from {{ ref('fivetran_log__connector_status') }}
),

api_calls as (

    select 
        connector_id,
        cast( {{ dbt_utils.date_trunc('day', 'created_at') }} as date) as date_day,
        count(*) as number_of_api_calls

    from {{ ref('stg_fivetran_log__log') }}

    where event_subtype='api_call'
        and connector_id is not null

    group by 1,2
),


connector_api_calls as (

    select
        api_calls.date_day,
        api_calls.number_of_api_calls,
        connector.connector_name,
        connector.connector_id,
        connector.connector_type,
        connector.destination_name,
        connector.destination_id,
        connector.set_up_at
    from
    connector left join api_calls 
        on api_calls.connector_id = connector.connector_id
),

spine as (

    {% if execute %}
    {% set first_date_query %}
        select  min( set_up_at ) as min_date from {{ ref('fivetran_log__connector_status') }}
    {% endset %}
    {% set first_date = run_query(first_date_query).columns[0][0]|string %}
    
    {% else %} {% set first_date = "'2016-01-01'" %}
    {% endif %}

    {{ dbt_utils.date_spine(
        datepart = "day", 
        start_date =  "'" ~ first_date[0:10] ~ "'", 
        end_date = dbt_utils.dateadd("week", 1, dbt_utils.date_trunc('day', dbt_utils.current_timestamp())) 
        ) 
    }} 
),

connector_api_call_history as (

    select
        cast(spine.date_day as date) as date_day,
        connector_api_calls.connector_name,
        connector_api_calls.connector_id,
        connector_api_calls.connector_type,
        connector_api_calls.destination_name,
        connector_api_calls.destination_id,
        max(case 
            when cast(spine.date_day as date) = connector_api_calls.date_day then connector_api_calls.number_of_api_calls
            else 0
        end) as number_of_api_calls
    from
    spine join connector_api_calls
        on spine.date_day  >= cast( {{ dbt_utils.date_trunc('day', 'connector_api_calls.set_up_at') }} as date)

    group by 1,2,3,4,5,6
),

-- now rejoin spine to get a complete calendar
join_api_call_history as (
    
    select
        spine.date_day,
        connector_api_call_history.connector_name,
        connector_api_call_history.connector_id,
        connector_api_call_history.connector_type,
        connector_api_call_history.destination_name,
        connector_api_call_history.destination_id,
        max(connector_api_call_history.number_of_api_calls) as number_of_api_calls

    from
    spine left join connector_api_call_history
        on cast(spine.date_day as date) = connector_api_call_history.date_day

    group by 1,2,3,4,5,6
),

final as (

    select *
    from join_api_call_history

    where cast(date_day as timestamp) <= {{ dbt_utils.current_timestamp() }}

    order by date_day desc
)

select *
from final