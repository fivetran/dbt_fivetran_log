{{ config(enabled=var('fivetran_platform_using_triggers', True)) }}

with base as (

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
    from base
)

select * 
from fields
where transformation_id is not null