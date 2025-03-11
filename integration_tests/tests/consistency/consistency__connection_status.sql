
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        1 as join_key,
        count(*) as total_records,
        sum(number_of_schema_changes_last_month) as total_schema_changes_last_month
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__connection_status
    group by 1
),

dev as (
    select
        1 as join_key,
        count(*) as total_records,
        sum(number_of_schema_changes_last_month) as total_schema_changes_last_month
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__connection_status
    group by 1
),

final as (
    select 
        prod.join_key,
        dev.join_key,
        prod.total_records as prod_total,
        dev.total_records as dev_total,
        prod.total_schema_changes_last_month as prod_total_schema_changes,
        dev.total_schema_changes_last_month as dev_total_schema_changes
    from prod
    left join dev 
        on dev.join_key = prod.join_key
)

select *
from final
where prod_total != dev_total
    or prod_total_schema_changes != dev_total_schema_changes