with trigger_table as (
    
    {% for source_destination in var('source_destinations')  %}
    select 
        *,
        '{{ source_destination }}' as source_destination
    from {{ source( source_destination, 'trigger_table') }} 
    {% if not loop.last -%} union all {%- endif %}
    {% endfor %}

),

fields as (

    select
        table,
        transformation_id,
        source_destination
        
    from trigger_table
)

select * from fields