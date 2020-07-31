with  credits_used as (

    {{ union_source_tables('credits_used') }}

),

fields as (
    
    select 
        destination_id,
        measured_month,
        credits_consumed,
        destination_database
    
    from credits_used
)

select * from fields