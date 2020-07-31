with account as (
    
    {{ union_source_tables('account') }}
    
),

fields as (

    select
        id as account_id,
        country,
        created_at,
        name as account_name,
        status,
        destination_database
        
    from account
)

select * from fields