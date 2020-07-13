with destination as (

    select *
    from {{ var('destination') }}

    -- union tables from multiple destinations here
),

fields as (

    select
        id as destination_id,
        account_id,
        created_at,
        name as destination_name,
        region
    
    from destination
)

select * from fields