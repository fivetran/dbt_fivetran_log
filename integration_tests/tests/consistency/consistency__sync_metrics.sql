
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        connection_id,
        count(*) as total_records,
        sum(extract_time_s) as sum_extract_time_s,
        sum(total_time_s) as sum_total_time_s,
        sum(total_extracted_rows) as sum_total_extracted_rows,
        sum(total_loaded_rows) as sum_total_loaded_rows
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__sync_metrics
    group by 1
),

dev as (
    select
        connection_id,
        count(*) as total_records,
        sum(extract_time_s) as sum_extract_time_s,
        sum(total_time_s) as sum_total_time_s,
        sum(total_extracted_rows) as sum_total_extracted_rows,
        sum(total_loaded_rows) as sum_total_loaded_rows
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__sync_metrics
    group by 1
),

final as (
    select
        prod.connection_id,
        prod.total_records as prod_total,
        dev.total_records as dev_total,
        prod.sum_extract_time_s as prod_sum_extract_time_s,
        dev.sum_extract_time_s as dev_sum_extract_time_s,
        prod.sum_total_time_s as prod_sum_total_time_s,
        dev.sum_total_time_s as dev_sum_total_time_s,
        prod.sum_total_extracted_rows as prod_sum_total_extracted_rows,
        dev.sum_total_extracted_rows as dev_sum_total_extracted_rows,
        prod.sum_total_loaded_rows as prod_sum_total_loaded_rows,
        dev.sum_total_loaded_rows as dev_sum_total_loaded_rows
    from prod
    left join dev
        on dev.connection_id = prod.connection_id
)

select *
from final
where prod_total != dev_total
    or abs(prod_sum_extract_time_s - dev_sum_extract_time_s) / nullif(prod_sum_extract_time_s, 0) > 0.01
    or abs(prod_sum_total_time_s - dev_sum_total_time_s) / nullif(prod_sum_total_time_s, 0) > 0.01
    or prod_sum_total_extracted_rows != dev_sum_total_extracted_rows
    or prod_sum_total_loaded_rows != dev_sum_total_loaded_rows
