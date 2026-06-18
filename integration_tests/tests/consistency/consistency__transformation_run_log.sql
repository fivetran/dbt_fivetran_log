
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        transformation_id,
        transformation_status,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__transformation_run_log
    group by 1, 2
),

dev as (
    select
        transformation_id,
        transformation_status,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__transformation_run_log
    group by 1, 2
),

final as (
    select
        prod.transformation_id,
        prod.transformation_status,
        prod.total_records as prod_total,
        dev.total_records as dev_total
    from prod
    left join dev
        on dev.transformation_id = prod.transformation_id
            and dev.transformation_status = prod.transformation_status
)

select *
from final
where prod_total != dev_total
