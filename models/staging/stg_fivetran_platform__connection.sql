with base as (

    select * 
    from {{ ref('stg_fivetran_platform__connection_tmp') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_fivetran_platform__connection_tmp')),
                staging_columns=get_connection_columns()
            )
        }}
        ,row_number() over ( partition by connection_name, destination_id order by _fivetran_synced desc ) as nth_last_record
    from base
),

final as (

    select 
        connection_id,
        connection_name,
        coalesce(connection_type_id, connection_type) as connection_type,
        destination_id,
        connecting_user_id,
        paused as is_paused,
        signed_up as set_up_at,
        coalesce(_fivetran_deleted,{{ ' 0 ' if target.type == 'sqlserver' else ' false'}}) as is_deleted
    from fields

    -- Only look at the most recent one
    where nth_last_record = 1
)

select * 
from final