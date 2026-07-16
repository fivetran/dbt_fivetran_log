
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        connection_id,
        count(*) as total_records,
        sum(total_events) as sum_total_events,
        sum(average_event_count) as sum_average_event_count
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__connection_event_variance
    group by 1
),

dev as (
    select
        connection_id,
        count(*) as total_records,
        sum(total_events) as sum_total_events,
        sum(average_event_count) as sum_average_event_count
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__connection_event_variance
    group by 1
),

final as (
    select
        prod.connection_id,
        prod.total_records as prod_total,
        dev.total_records as dev_total,
        prod.sum_total_events as prod_sum_total_events,
        dev.sum_total_events as dev_sum_total_events,
        prod.sum_average_event_count as prod_sum_average_event_count,
        dev.sum_average_event_count as dev_sum_average_event_count
    from prod
    left join dev
        on dev.connection_id = prod.connection_id
)

select *
from final
where prod_total != dev_total
    or prod_sum_total_events != dev_sum_total_events
    or prod_sum_average_event_count != dev_sum_average_event_count
