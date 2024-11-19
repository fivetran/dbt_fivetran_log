
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        date_day,
        connector_id, 
        destination_id,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__connector_daily_events
    group by 1, 2, 3
),

dev as (
    select
        date_day,
        connector_id, 
        destination_id,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__connector_daily_events
    group by 1, 2, 3
),

final as (
    select 
        prod.date_day,
        prod.connector_id,
        prod.destination_id,
        prod.total_records as prod_total,
        dev.total_records as dev_total
    from prod
    left join dev 
        on dev.date_day = prod.date_day
            and dev.connector_id = prod.connector_id
            and dev.destination_id = prod.destination_id
)

select *
from final
where prod_total != dev_total