{% set a = enable_model('trigger_model') %}
{{ config(enabled=var('a', false) ) }}

with trigger_table as (
    

    {{ union_source_tables('trigger_table') }}

),

fields as (

    select
        table,
        transformation_id,
        destination_database
        
    from trigger_table
)

select * from fields