with connection_base as (
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

sorted_rows as (
    select
        {{ 'connection_id' if var('fivetran_platform_using_connection', True) else 'connector_id' }} as connection_id,
        {{ 'connection_name' if var('fivetran_platform_using_connection', True) else 'connector_name' }} as connection_name,
        connector_type_id,
        {{ fivetran_log.coalesce_cast(['connector_type_id', 'connector_type'], dbt.type_string()) }} as connector_type,
        destination_id,
        connecting_user_id,
        paused as is_paused,
        signed_up as set_up_at,
        coalesce(_fivetran_deleted, {{ ' 0 ' if target.type == 'sqlserver' else ' false' }}) as is_deleted,
        row_number() over (partition by connection_name, destination_id order by _fivetran_synced desc) as nth_last_record
    from connection_fields
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