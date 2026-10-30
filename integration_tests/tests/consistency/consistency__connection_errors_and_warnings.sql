
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        connection_id,
        is_custom_connector,
        severity_level,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__connection_errors_and_warnings
    group by 1, 2, 3
),

dev as (
    select
        connection_id,
        is_custom_connector,
        severity_level,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__connection_errors_and_warnings
    group by 1, 2, 3
),

final as (
    select
        prod.connection_id,
        prod.is_custom_connector,
        prod.severity_level,
        prod.total_records as prod_total,
        dev.total_records as dev_total
    from prod
    left join dev
        on dev.connection_id = prod.connection_id
        and dev.is_custom_connector = prod.is_custom_connector
        and dev.severity_level = prod.severity_level
)

select *
from final
where prod_total != dev_total
