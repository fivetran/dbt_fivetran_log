with trigger_table as (

    {% if var('unioning_multiple_destinations', false) is true %}
    {{ union_source_tables('trigger_table') }}

    {% else %}
    {{ handle_no_transformations('trigger_table') }}
    
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
        
        {% if var('unioning_multiple_destinations', false) is true -%}
        destination_database
        {% else -%}
        {{ "'" ~ var('fivetran_log_database', target.database) ~ "'" }} 
        {%- endif %} as destination_database
    
    from trigger_table
    
)

select * from fields
where transformation_id is not null