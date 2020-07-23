with connector as (

    {% for source_destination in var('source_destinations')  %}
    select 
        *,
        '{{ source_destination }}' as source_destination
    from {{ source( source_destination, 'connector') }} 
    {% if not loop.last -%} union all {%- endif %}
    {% endfor %}

),

fields as (

    select 
        connector_id,
        connecting_user_id,
        connector_name,
        connector_type,  -- use coalesce(connector_type, service) if the table has a service column (deprecated)
        destination_id,
        paused as is_paused,
        signed_up as signed_up_at,
        source_destination

    from connector
)

select * from fields