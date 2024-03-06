
{{ config(
    tags="validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with end_model as (
    select 
        measured_month,
        destination_id,
        count(*) as row_count
    from {{ ref('fivetran_platform__usage_mar_destination_history') }}
    group by measured_month, destination_id
),

staging_model as (
    select
        cast({{ dbt.date_trunc('month', 'measured_date') }} as date) as measured_month,
        destination_id
    from {{ ref('stg_fivetran_platform__incremental_mar') }}
    group by cast({{ dbt.date_trunc('month', 'measured_date') }} as date), destination_id
),

staging_cleanup as (
    select 
        measured_month,
        destination_id,
        count(*) as row_count
    from staging_model
    group by measured_month, destination_id
)

select 
    end_model.measured_month,
    end_model.destination_id,
    end_model.row_count as end_model_row_count,
    staging_cleanup.row_count as staging_model_row_count
from end_model
left join staging_cleanup
    on end_model.destination_id = staging_cleanup.destination_id
    and end_model.measured_month = staging_cleanup.measured_month
where staging_cleanup.row_count != end_model.row_count