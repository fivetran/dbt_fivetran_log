with  credits_used as (

    select * from {{ var('credits_used') }}

),

fields as (
    
    select 
        destination_id,
        measured_month,
        credits_consumed
    
    from credits_used
)

select * from fields