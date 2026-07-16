
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        connection_id,
        count(*) as total_records,
        sum(rows_modified) as sum_rows_modified,
        sum(average_rows_modified) as sum_average_rows_modified
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__records_modified_variance
    group by 1
),

dev as (
    select
        connection_id,
        count(*) as total_records,
        sum(rows_modified) as sum_rows_modified,
        sum(average_rows_modified) as sum_average_rows_modified
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__records_modified_variance
    group by 1
),

final as (
    select
        prod.connection_id,
        prod.total_records as prod_total,
        dev.total_records as dev_total,
        prod.sum_rows_modified as prod_sum_rows_modified,
        dev.sum_rows_modified as dev_sum_rows_modified,
        prod.sum_average_rows_modified as prod_sum_average_rows_modified,
        dev.sum_average_rows_modified as dev_sum_average_rows_modified
    from prod
    left join dev
        on dev.connection_id = prod.connection_id
)

select *
from final
where prod_total != dev_total
    or prod_sum_rows_modified != dev_sum_rows_modified
    or prod_sum_average_rows_modified != dev_sum_average_rows_modified
