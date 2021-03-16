with account_membership as (
    
    select * from {{ var('account_membership') }}

),

fields as (

    select
        account_id,
        user_id,
        activated_at,
        joined_at,
        role as account_role
        
    from account_membership
    
)

select * from fields