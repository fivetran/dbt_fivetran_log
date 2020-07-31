with account_membership as (
    
    {{ union_source_tables('account_membership') }}

),

fields as (

    select
        account_id,
        user_id,
        activated_at,
        joined_at,
        role as account_role,
        destination_database
        
    from account_membership
)

select * from fields