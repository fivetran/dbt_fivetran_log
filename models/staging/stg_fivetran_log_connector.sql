with connector as (

    {{ union_source_tables('connector') }}

),

fields as (

    select 
        connector_id,
        connector_name,
        connector_type,  -- use coalesce(connector_type, service) if the table has a service column (deprecated)
        destination_id,
        connecting_user_id,
        paused as is_paused,
        signed_up as set_up_at,
        destination_database,

        -- Consolidating duplicate connectors (ie deleted and then re-added)
        row_number() over ( partition by connector_name, destination_id order by _fivetran_synced desc ) as nth_last_record

    from connector

),

final as (

    select 
        connector_id,
        connector_name,
        connector_type, 
        destination_id,
        connecting_user_id,
        is_paused,
        set_up_at,
        destination_database

    from fields

    -- Only look at the most recent one
    where nth_last_record = 1
)

select * from final