with transformation as (
    
    {% for source_destination in var('source_destinations_with_transformations')  %}
    select 
        *,
        '{{ source_destination }}' as source_destination
    from {{ source( source_destination, 'transformation') }} 
    {% if not loop.last -%} union all {%- endif %}
    {% endfor %}

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
        source_destination
        
    from transformation
)

select * from fields