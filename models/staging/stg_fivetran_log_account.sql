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
        {{ string_agg( 'destination_database', "', '") }} as destination_databases
        
    from account

    group by 1,2,3,4,5
)

select * from fields