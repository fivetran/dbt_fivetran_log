with active_volume as (
    
    {% for source_destination in var('source_destinations')  %}
    select 
        *,
        '{{ source_destination }}' as source_destination
    from {{ source( source_destination, 'active_volume') }} 
    {% if not loop.last -%} union all {%- endif %}
    {% endfor %}

),

fields as (

    select
        id as active_volume_id,
        connector_id,
        destination_id,
        measured_at,
        monthly_active_rows,
        schema_name,
        table_name,
        source_destination
    
    from active_volume
)

select * from fields