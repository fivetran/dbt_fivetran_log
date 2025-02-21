
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with end_model as (
    select
        measured_month,
        destination_id,
        sum(total_model_runs) as total_model_runs,
        sum(paid_model_runs) as paid_model_runs,
        sum(free_model_runs) as free_model_runs
    from {{ ref('fivetran_platform__usage_mar_destination_history') }}
    group by 1,2
),

staging_model as (
    select
        measured_month,
        destination_id,
        sum(model_runs) as total_model_runs, 
        sum(case when free_type = 'PAID' then model_runs else 0 end) as paid_model_runs, 
        sum(case when free_type != 'PAID' then model_runs else 0 end) as free_model_runs
    from {{ ref('stg_fivetran_platform__transformation_runs') }}
    group by 1,2
)

select 
    end_model.measured_month,
    end_model.destination_id,
    end_model.total_model_runs,
    end_model.paid_model_runs,
    end_model.free_model_runs,
    staging_model.total_model_runs,
    staging_model.paid_model_runs,
    staging_model.free_model_runs
from end_model
left join staging_model
    on end_model.destination_id = staging_model.destination_id
    and end_model.measured_month = staging_model.measured_month
where staging_model.total_model_runs != end_model.total_model_runs
or staging_model.paid_model_runs != end_model.paid_model_runs
or staging_model.free_model_runs != end_model.free_model_runs