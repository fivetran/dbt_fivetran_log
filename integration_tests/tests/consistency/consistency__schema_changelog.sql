
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        connection_id, 
        table_name,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__schema_changelog
    group by 1, 2
),

dev as (
    select
        connection_id, 
        table_name,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__schema_changelog
    group by 1, 2
),

final as (
    select 
        prod.connection_id,
        prod.table_name,
        prod.total_records as prod_total,
        dev.total_records as dev_total
    from prod
    left join dev 
        on dev.connection_id = prod.connection_id
            and dev.table_name = prod.table_name
)

select *
from final
where prod_total != dev_total