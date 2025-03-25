{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}


with prod as (

    select
        date_day, 
        day_name,
        day_of_month,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__audit_user_activity
    group by 1, 2, 3
),

dev as (

    select
        date_day, 
        day_name,
        day_of_month,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__audit_user_activity
    group by 1, 2, 3
),

final as (
    
    select 
        prod.date_day,
        prod.day_name,
        prod.day_of_month,
        prod.total_records as prod_total,
        dev.total_records as dev_total
    from prod
    left join dev 
        on dev.date_day = prod.date_day
            and dev.day_name = prod.day_name
            and dev.day_of_month = prod.day_of_month
)

select *
from final
where prod_total != dev_total