with connector as (
    
    select *
    from {{ var('connector' ) }}
),

fields as (

    select 
        connector_id,
        connecting_user_id,
        connector_name,
        connector_type,
        -- coalesce(connector_type, service) as connector_type, -- use if table has service
        destination_id,
        paused as is_paused,
        signed_up as signed_up_at

    from connector
)

select * from fields