with connector as (

    select * 
    from {{ ref('stg_fivetran_log__connector_tmp') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_fivetran_log__connector_tmp')),
                staging_columns=get_connector_columns()
            )
        }}
        ,row_number() over ( partition by connector_name, destination_id order by _fivetran_synced desc ) as nth_last_record
    from connector
),

final as (

    select 
        connector_id,
        connector_name,
        coalesce(connector_type_id, connector_type) as connector_type,
        destination_id,
        connecting_user_id,
        paused as is_paused,
        signed_up as set_up_at
    from fields

    -- Only look at the most recent one
    where nth_last_record = 1
)

select * 
from final