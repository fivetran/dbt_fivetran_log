with transformation as (
    
    select * 
    from {{ var('transformation') }}

    -- union tables from multiple destinations here
),

fields as (

    select
        id as transformation_id,
        created_at,
        created_by_id as created_by_user_id,
        destination_id,
        name as transformation_name,
        paused as is_paused,
        script,
        trigger_delay,
        trigger_interval,
        trigger_type
        
    from transformation
)

select * from fields