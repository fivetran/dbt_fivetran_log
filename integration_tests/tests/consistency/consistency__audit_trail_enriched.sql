
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        action,
        primary_resource_type,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__audit_trail_enriched
    group by 1, 2
),

dev as (
    select
        action,
        primary_resource_type,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__audit_trail_enriched
    group by 1, 2
),

final as (
    select
        prod.action,
        prod.primary_resource_type,
        prod.total_records as prod_total,
        dev.total_records as dev_total
    from prod
    left join dev
        on dev.action = prod.action
            and dev.primary_resource_type = prod.primary_resource_type
)

select *
from final
where prod_total != dev_total
