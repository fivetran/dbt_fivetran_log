
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        date_day,
        connection_id, 
        destination_id,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__connection_daily_events
    group by 1, 2, 3
),

dev as (
    select
        date_day,
        connection_id, 
        destination_id,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__connection_daily_events
    group by 1, 2, 3
),

final as (
    select 
        prod.date_day,
        prod.connection_id,
        prod.destination_id,
        prod.total_records as prod_total,
        dev.total_records as dev_total
    from prod
    left join dev 
        on dev.date_day = prod.date_day
            and dev.connection_id = prod.connection_id
            and dev.destination_id = prod.destination_id
)

select *
from final
where prod_total != dev_total