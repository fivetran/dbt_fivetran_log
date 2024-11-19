
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        connector_id, 
        email,
        date_day,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__audit_user_activity
    group by 1, 2, 3
),

dev as (
    select
        connector_id, 
        email,
        date_day,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__audit_user_activity
    group by 1, 2, 3
),

final as (
    select 
        prod.connector_id,
        prod.email,
        prod.date_day,
        prod.total_records as prod_total,
        dev.total_records as dev_total
    from prod
    left join dev 
        on dev.connector_id = prod.connector_id
            and dev.email = prod.email
            and dev.date_day = prod.date_day
)

select *
from final
where prod_total != dev_total