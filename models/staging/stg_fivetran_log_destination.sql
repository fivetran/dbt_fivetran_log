with destination as (

    {% if var('unioning_multiple_destinations', false) is true %}
    {{ union_source_tables('destination') }}

    {% else %}
    select * from {{ var('destination') }}
    
    {% endif %}

),

fields as (

    select
        id as destination_id,
        account_id,
        created_at,
        name as destination_name,
        region,
        {% if var('unioning_multiple_destinations', false) is true -%}
        destination_database
        {% else -%}
        {{ "'" ~ var('fivetran_log_database', target.database) ~ "'" }} 
        {%- endif %} as destination_database
    
    from destination
)

select * from fields