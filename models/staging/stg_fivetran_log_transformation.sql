with transformation as (
    
    {% if unioning_multiple_destinations is true %}
    {{ union_source_tables('transformation') }}

    {% else %}
    select * from {{ var('transformation') }}
    
    {% endif %}
),

fields as (

    select
        id as transformation_id,
        created_at,
        created_by_id as created_by_user_id,
        destination_id,
        name as transformation_name,
        paused as is_paused,
        script,
        trigger_delay,
        trigger_interval,
        trigger_type,
        {% if unioning_multiple_destinations is true -%}
        destination_database
        {% else -%}
        {{ "'" ~ var('fivetran_log_database', target.database) ~ "'" }} 
        {%- endif %} as destination_database
        
    from transformation
    
)

select * from fields
where destination_database is not null