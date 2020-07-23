with  credits_used as (

    {% for source_destination in var('source_destinations')  %}
    select 
        *,
        '{{ source_destination }}' as source_destination
    from {{ source( source_destination, 'credits_used') }} 
    {% if not loop.last -%} union all {%- endif %}
    {% endfor %}

),

fields as (
    
    select 
        destination_id,
        measured_month,
        credits_consumed,
        source_destination
    
    from credits_used
)

select * from fields