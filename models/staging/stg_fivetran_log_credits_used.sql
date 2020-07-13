with  credits_used as (

    select *
    from {{ var('credits_used') }}

    -- union tables from multiple destinations here
),

fields as (
    
    select 
        destination_id,
        measured_month,
        credits_consumed
    
    from credits_used
)

select * from fields