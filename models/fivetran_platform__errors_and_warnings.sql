with log_events as (

    select
        connection_id,
        sync_id,
        created_at as event_time,
        event_type as severity_level,
        message_data as message,
        'standard_connector' as connector_type
    from {{ ref('stg_fivetran_platform__log') }}
    -- limit to error and warning severities; excludes INFO and non-severity event types (e.g. TRANSFORMATION)
    where lower(event_type) in ('warning', 'error', 'severe')
),

{% if var('fivetran_platform_using_connector_sdk_log', true) -%}
connector_sdk_events as (

    select
        connection_id,
        sync_id,
        created_at as event_time,
        level as severity_level,
        message,
        'connector_sdk' as connector_type
    from {{ ref('stg_fivetran_platform__connector_sdk_log') }}
    where lower(level) in ('warning', 'error', 'severe')
),
{%- endif %}

unioned as (

    select * from log_events

    {% if var('fivetran_platform_using_connector_sdk_log', true) -%}
    union all
    select * from connector_sdk_events
    {%- endif %}
),

connection as (

    select
        connection_id,
        connection_name
    from {{ ref('stg_fivetran_platform__connection') }}
),

final as (

    select
        unioned.connection_id,
        connection.connection_name,
        unioned.event_time,
        unioned.severity_level,
        unioned.message,
        unioned.connector_type,
        unioned.sync_id
    from unioned
    left join connection
        on unioned.connection_id = connection.connection_id
)

select *
from final
