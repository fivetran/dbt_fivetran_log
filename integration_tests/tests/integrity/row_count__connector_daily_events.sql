
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with end_model as (
    select 
        date_day,
        connector_id, 
        destination_id,
        count(*) as row_count
    from {{ ref('fivetran_platform__connector_daily_events') }}
    group by date_day, connector_id, destination_id
),

staging_model as (
    
    select * 
    from {{ ref('fivetran_platform__connector_status') }}
),

spine as (

    {% if execute %}
    {% set first_date_query %}
        select  min( signed_up ) as min_date from {{ source('fivetran_platform','connector') }}
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

staging_cleanup as (
    select 
        spine.date_day,
        staging_model.connector_id,
        staging_model.destination_id,
        count(*) as row_count
    from spine
    left join staging_model
        on spine.date_day >= cast({{ dbt.date_trunc('day', 'cast(staging_model.set_up_at as date)') }} as date)
    group by spine.date_day, staging_model.connector_id, staging_model.destination_id
)

select 
    end_model.date_day,
    end_model.connector_id,
    end_model.destination_id,
    end_model.row_count as end_model_row_count,
    staging_cleanup.row_count as staging_model_row_count
from end_model
left join staging_cleanup
    on end_model.connector_id = staging_cleanup.connector_id
    and end_model.destination_id = staging_cleanup.destination_id
    and end_model.date_day = staging_cleanup.date_day
where staging_cleanup.row_count != end_model.row_count