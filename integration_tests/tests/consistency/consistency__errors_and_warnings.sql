
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        connection_id,
        connector_type,
        severity_level,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__errors_and_warnings
    group by 1, 2, 3
),

dev as (
    select
        connection_id,
        connector_type,
        severity_level,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__errors_and_warnings
    group by 1, 2, 3
),

final as (
    select
        prod.connection_id,
        prod.connector_type,
        prod.severity_level,
        prod.total_records as prod_total,
        dev.total_records as dev_total
    from prod
    left join dev
        on dev.connection_id = prod.connection_id
        and dev.connector_type = prod.connector_type
        and dev.severity_level = prod.severity_level
)

select *
from final
where prod_total != dev_total
