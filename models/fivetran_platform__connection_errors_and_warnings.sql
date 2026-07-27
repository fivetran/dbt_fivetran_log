with log_events as (

    select
        log_id as event_id,
        connection_id,
        sync_id,
        created_at as event_time,
        event_type as severity_level,
        message_data as message,
        {{ '0' if target.type == 'sqlserver' else 'false' }} as is_custom_connector
        -- standard connector
    from {{ ref('stg_fivetran_platform__log') }}
    -- Excludes events not attributable to a connection (connection_id is null), such as transformation job dbt run logs, which are not connector events.
    where lower(event_type) in ('warning', 'error', 'severe')
        and connection_id is not null
),

{% if var('fivetran_platform_using_connector_sdk_log', true) -%}
connector_sdk_events as (

    select
        connector_sdk_log_id as event_id,
        connection_id,
        sync_id,
        created_at as event_time,
        level as severity_level,
        message,
        {{ '1' if target.type == 'sqlserver' else 'true' }} as is_custom_connector
        -- connector sdk
    from {{ ref('stg_fivetran_platform__connector_sdk_log') }}
    where lower(level) in ('warning', 'error', 'severe')
        and connection_id is not null
),
{%- endif %}

unioned as (

    select * 
    from log_events

    {% if var('fivetran_platform_using_connector_sdk_log', true) -%}
    union all
    
    select * 
    from connector_sdk_events
    {%- endif %}
),

connection_ranked as (

    select
        connection_id,
        connection_name,
        row_number() over (partition by connection_id order by connection_name) as connection_row
    from {{ ref('stg_fivetran_platform__connection') }}
),

connection as (

    -- dedupe to one row per connection_id to avoid fanning out events on the join below.
    select
        connection_id,
        connection_name
    from connection_ranked
    where connection_row = 1
),

final as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'unioned.event_id',
            'unioned.connection_id',
            'unioned.sync_id',
            'unioned.event_time'
        ]) }} as unique_error_warning_key,
        unioned.connection_id,
        connection.connection_name,
        unioned.event_time,
        unioned.severity_level,
        unioned.message,
        unioned.is_custom_connector,
        unioned.sync_id
    from unioned
    left join connection
        on unioned.connection_id = connection.connection_id
)

select *
from final
