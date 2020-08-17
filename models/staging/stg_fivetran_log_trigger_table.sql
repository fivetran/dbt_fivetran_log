with trigger_table as (

    {% if unioning_multiple_destinations is true %}
    {{ union_source_tables('trigger_table') }}

    {% else %}
    select * from {{ var('trigger_table') }}
    
    {% endif %}

),

fields as (

    select 
        {% if target.type == 'bigquery' %} 
        table as trigger_table, 
        {% else %} 
        "TABLE" as trigger_table,
        {% endif %}
        
        transformation_id,
        
        {% if unioning_multiple_destinations is true -%}
        destination_database
        {% else -%}
        {{ "'" ~ var('fivetran_log_database', target.database) ~ "'" }} 
        {%- endif %} as destination_database
    
    from trigger_table
    
)

select * from fields
where destination_database is not null