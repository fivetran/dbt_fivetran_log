
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        measured_month,
        destination_id,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__usage_history
    group by 1, 2
),

dev as (
    select
        measured_month,
        destination_id,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__usage_history
    group by 1, 2
),

final as (
    select 
        prod.measured_month,
        prod.destination_id,
        prod.total_records as prod_total,
        dev.total_records as dev_total
    from prod
    left join dev 
        on dev.measured_month = prod.measured_month
            and dev.destination_id = prod.destination_id
)

select *
from final
where prod_total != dev_total