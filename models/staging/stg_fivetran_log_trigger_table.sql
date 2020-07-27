with trigger_table as (
    
    select * from 
    {{ union_source_tables('trigger_table') }}

),

fields as (

    select
        table,
        transformation_id,
        source_destination
        
    from trigger_table
)

select * from fields