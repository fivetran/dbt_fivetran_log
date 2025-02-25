/* 
The CONNECTOR source is deprecated in favor of CONNECTION.
This model merges data from both source tables, handling any combination of the tables being present (either one or both).
The configuration variables `fivetran_platform_using_connection` and `fivetran_platform_using_connector` is ideally set 
by Quickstart, but a core user can also customize. 
It combines records from both sources into a single output and deduplicates across the two sources.
This logic will be removed when the CONNECTOR source is removed.
*/

{% set using_connection = var('fivetran_platform_using_connection', True) %}
{% set using_connector = var('fivetran_platform_using_connector', False) %}

with 

{% if using_connection -%}
    connection_base as (
        select * 
        from {{ ref('stg_fivetran_platform__connection_tmp') }}
    ),

    connection_fields as (
        select
            {{
                fivetran_utils.fill_staging_columns(
                    source_columns=adapter.get_columns_in_relation(ref('stg_fivetran_platform__connection_tmp')),
                    staging_columns=get_connection_columns()
                )
            }}
        from connection_base
    ),
{% endif %}

{% if using_connector -%}
    connector_base as (
        select * 
        from {{ ref('stg_fivetran_platform__connector_tmp') }}
    ),

    connector_fields as (
        select
            {{
                fivetran_utils.fill_staging_columns(
                    source_columns=adapter.get_columns_in_relation(ref('stg_fivetran_platform__connector_tmp')),
                    staging_columns=get_connector_columns()
                )
            }}
        from connector_base
    ),
{% endif %}

unioned as (

{% if using_connection -%}
    select 
        connection_id,
        connection_name,
        connector_type_id,
        connector_type,
        destination_id,
        connecting_user_id,
        paused,
        signed_up,
        _fivetran_deleted,
        _fivetran_synced
    from connection_fields
{% endif %}

{% if using_connection and using_connector -%}
    union all
{% endif %}

{% if using_connector -%}
    select 
        connector_id as connection_id,
        connector_name as connection_name,
        connector_type_id,
        connector_type,
        destination_id,
        connecting_user_id,
        paused,
        signed_up,
        _fivetran_deleted,
        _fivetran_synced
    from connector_fields
{% endif %}
),

sorted_rows as (
    select
        connection_id,
        connection_name,
        {{ fivetran_log.coalesce_cast(['connector_type_id', 'connector_type'], dbt.type_string()) }} as connector_type,
        destination_id,
        connecting_user_id,
        paused as is_paused,
        signed_up as set_up_at,
        coalesce(_fivetran_deleted, {{ ' 0 ' if target.type == 'sqlserver' else ' false' }}) as is_deleted,
        row_number() over (partition by connection_name, destination_id order by _fivetran_synced desc) as nth_last_record
    from unioned
),

final as (
    select
        connection_id,
        connection_name,
        connector_type,
        destination_id,
        connecting_user_id,
        is_paused,
        set_up_at,
        is_deleted
    from sorted_rows
    where nth_last_record = 1
)

select * 
from final