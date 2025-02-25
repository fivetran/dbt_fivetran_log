
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        connection_name,
        schema_name,
        table_name,
        destination_id,
        measured_month,
        sum(total_monthly_active_rows) as total_mar,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__mar_table_history
    group by 1, 2, 3, 4, 5
),

dev as (
    select
        connection_name,
        schema_name,
        table_name,
        destination_id,
        measured_month,
        sum(total_monthly_active_rows) as total_mar,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__mar_table_history
    group by 1, 2, 3, 4, 5
),

final as (
    select 
        prod.connection_name,
        prod.schema_name,
        prod.table_name,
        prod.destination_id,
        prod.measured_month,
        prod.total_records as prod_total,
        dev.total_records as dev_total,
        prod.total_mar as prod_total_mar,
        dev.total_mar as dev_total_mar
    from prod
    left join dev 
        on dev.connection_name = prod.connection_name
            and dev.schema_name = prod.schema_name
            and dev.table_name = prod.table_name
            and dev.destination_id = prod.destination_id
            and dev.measured_month = prod.measured_month
)

select *
from final
where prod_total != dev_total
    or prod_total_mar != dev_total_mar