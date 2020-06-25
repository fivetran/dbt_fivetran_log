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
        destination_id,
        paused as is_paused,
        signed_up as signed_up_at

    from connector
)

select * from fields