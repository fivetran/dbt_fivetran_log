with connector as (
    
    select *
    from {{ var('connector' ) }}

    -- union tables from multiple destinations here
),

fields as (

    select 
        connector_id,
        connecting_user_id,
        connector_name,
        connector_type,
        -- coalesce(connector_type, service)  -- use if table has a service columns
        destination_id,
        paused as is_paused,
        signed_up as signed_up_at

    from connector
)

select * from fields