with transformation as (
    
    {{ union_source_tables('transformation') }}

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
        trigger_type,
        destination_database
        
    from transformation

    where destination_database is not null
)

select * from fields