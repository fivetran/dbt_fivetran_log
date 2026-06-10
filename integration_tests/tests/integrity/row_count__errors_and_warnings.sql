
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- Verifies the end model preserves one row per source error/warning event (no fan-out or loss from the connection join).
with end_model as (
    select
        connector_type,
        count(*) as row_count
    from {{ ref('fivetran_platform__errors_and_warnings') }}
    group by 1
),

staging_model as (
    select
        'standard_connector' as connector_type,
        count(*) as row_count
    from {{ ref('stg_fivetran_platform__log') }}
    where lower(event_type) in ('warning', 'error', 'severe')

    {% if var('fivetran_platform_using_connector_sdk_log', true) %}
    union all
    select
        'connector_sdk' as connector_type,
        count(*) as row_count
    from {{ ref('stg_fivetran_platform__connector_sdk_log') }}
    where lower(level) in ('warning', 'error', 'severe')
    {% endif %}
)

select
    end_model.connector_type,
    end_model.row_count as end_model_row_count,
    staging_model.row_count as staging_model_row_count
from end_model
left join staging_model
    on end_model.connector_type = staging_model.connector_type
where end_model.row_count != staging_model.row_count
