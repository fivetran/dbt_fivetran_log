with account as (
    
    select * 
    from {{ var('account') }}

    -- union tables from multiple destinations here
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