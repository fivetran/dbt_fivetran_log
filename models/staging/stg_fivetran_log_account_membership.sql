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
        {{ string_agg( 'destination_database', "', '") }} as destination_databases
        
    from account_membership
    group by 1,2,3,4,5
    
)

select * from fields