
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with end_model as (
    select
        transformation_id,
        count(*) as row_count
    from {{ ref('fivetran_platform__transformation_run_log') }}
    group by transformation_id
),

staging_model as (
    select
        {{ fivetran_log.fivetran_log_json_parse(string="message_data", string_path=["id"]) }} as transformation_id,
        count(*) as row_count
    from {{ ref('stg_fivetran_platform__log') }}
    where event_subtype like '%transformation%'
        and event_subtype != 'transformation_start'
    group by 1
)

select
    end_model.transformation_id,
    end_model.row_count as end_model_row_count,
    staging_model.row_count as staging_model_row_count
from end_model
left join staging_model
    on staging_model.transformation_id = end_model.transformation_id
where staging_model.row_count != end_model.row_count
