with destination_membership as (
    
    {{ union_source_tables('destination_membership') }}

),

fields as (

    select
        destination_id,
        user_id,
        activated_at,
        joined_at,
        role as destination_role,
        destination_database
        
    from destination_membership
)

select * from fields