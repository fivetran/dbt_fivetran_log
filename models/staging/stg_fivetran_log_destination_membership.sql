with destination_membership as (
    
    {% for source_destination in var('source_destinations')  %}
    select 
        *,
        '{{ source_destination }}' as source_destination
    from {{ source( source_destination, 'destination_membership') }} 
    {% if not loop.last -%} union all {%- endif %}
    {% endfor %}

),

fields as (

    select
        destination_id,
        user_id,
        activated_at,
        joined_at,
        role as destination_role,
        source_destination
        
    from destination_membership
)

select * from fields