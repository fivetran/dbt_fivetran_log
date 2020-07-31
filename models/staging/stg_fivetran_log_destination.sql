with destination as (

    {{ union_source_tables('destination') }}

),

fields as (

    select
        id as destination_id,
        account_id,
        created_at,
        name as destination_name,
        region,
        destination_database
    
    from destination
)

select * from fields