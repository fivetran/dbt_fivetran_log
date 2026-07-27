
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- Verifies the end model preserves one row per source error/warning event (no fan-out or loss from the connection join).
with end_model as (
    select
        is_custom_connector,
        count(*) as row_count
    from {{ ref('fivetran_platform__connection_errors_and_warnings') }}
    group by 1
),

staging_model as (
    select
        {{ '0' if target.type == 'sqlserver' else 'false' }} as is_custom_connector,
        count(*) as row_count
    from {{ ref('stg_fivetran_platform__log') }}
    where lower(event_type) in ('warning', 'error', 'severe')
        and connection_id is not null

    {% if var('fivetran_platform_using_connector_sdk_log', false) %}
    union all
    select
        {{ '1' if target.type == 'sqlserver' else 'true' }} as is_custom_connector,
        count(*) as row_count
    from {{ ref('stg_fivetran_platform__connector_sdk_log') }}
    where lower(level) in ('warning', 'error', 'severe')
        and connection_id is not null
    {% endif %}
)

select
    end_model.is_custom_connector,
    end_model.row_count as end_model_row_count,
    staging_model.row_count as staging_model_row_count
from end_model
left join staging_model
    on end_model.is_custom_connector = staging_model.is_custom_connector
where end_model.row_count != staging_model.row_count
