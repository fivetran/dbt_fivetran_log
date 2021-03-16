with account as (
    
    select * from {{ var('account') }}

),

fields as (

    select
        id as account_id,
        country,
        created_at,
        name as account_name,
        status
        
    from account

)

select * from fields