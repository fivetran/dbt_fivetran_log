with  credits_used as (

    {% if unioning_multiple_destinations is true %}
    {{ union_source_tables('credits_used') }}

    {% else %}
    select * from {{ var('credits_used') }}
    
    {% endif %}

),

fields as (
    
    select 
        destination_id,
        measured_month,
        credits_consumed,
        {% if unioning_multiple_destinations is true -%}
        destination_database
        {% else -%}
        {{ "'" ~ var('fivetran_log_database', target.database) ~ "'" }} 
        {%- endif %} as destination_database
    
    from credits_used
)

select * from fields