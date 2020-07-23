with destination as (

    {% for source_destination in var('source_destinations')  %}
    select 
        *,
        '{{ source_destination }}' as source_destination
    from {{ source( source_destination, 'destination') }} 
    {% if not loop.last -%} union all {%- endif %}
    {% endfor %}

),

fields as (

    select
        id as destination_id,
        account_id,
        created_at,
        name as destination_name,
        region,
        source_destination
    
    from destination
)

select * from fields