with trigger_table as (
    
    select * 
    from {{ var('trigger_table') }}

    -- union tables from multiple destinations here
),

fields as (

    select
        table,
        transformation_id
        
    from trigger_table
)

select * from fields