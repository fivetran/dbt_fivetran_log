with destination_membership as (
    
    {% if var('unioning_multiple_destinations', false) is true %}
    {{ union_source_tables('destination_membership') }}

    {% else %}
    select * from {{ var('destination_membership') }}
    
    {% endif %}
),

fields as (

    select
        destination_id,
        user_id,
        activated_at,
        joined_at,
        role as destination_role,
        {% if var('unioning_multiple_destinations', false) is true -%}
        destination_database
        {% else -%}
        {{ "'" ~ var('fivetran_log_database', target.database) ~ "'" }} 
        {%- endif %} as destination_database
        
    from destination_membership
)

select * from fields