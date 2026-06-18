{{ config(enabled=var('fivetran_platform_using_connector_sdk_log', true)) }}

with base as (

    select *
    from {{ var('connector_sdk_log') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('fivetran_platform', 'connector_sdk_log')),
                staging_columns=get_connector_sdk_log_columns()
            )
        }}
    from base
),

final as (

    select
        id as connector_sdk_log_id,
        sync_id,
        connection_id,
        cast(event_time as {{ dbt.type_timestamp() }}) as created_at,
        level,
        message,
        message_origin
    from fields
)

select *
from final
