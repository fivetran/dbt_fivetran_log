{{ config(enabled=var('fivetran_log_using_triggers', True)) }}

with trigger_table as (

    select * 
    from {{ var('trigger_table') }}
),

fields as (

    select 
        {% if target.type == 'bigquery' %} 
        table as trigger_table, 
        {% elif target.type == 'postgres' %}
        "table" as trigger_table,
        {% else %} 
        "TABLE" as trigger_table,
        {% endif %}
        transformation_id
    from trigger_table
)

select * 
from fields
where transformation_id is not null