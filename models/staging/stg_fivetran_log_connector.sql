with connector as (
    
    {% set destinations =  [ 'fivetran_log_bigquery' ] %} -- add defined source names

    {% for destination in destinations  %}
    select 
        *,
        '{{ destination }}' as destination
    from {{ source( destination, 'connector') }} 
    {% if not loop.last -%} union all {%- endif %}
    {% endfor %}

    -- union tables from multiple destinations here
),

fields as (

    select 
        connector_id,
        connecting_user_id,
        connector_name,
        connector_type,  -- use coalesce(connector_type, service)  if the table has a service column (deprecated)
        destination_id,
        paused as is_paused,
        signed_up as signed_up_at

    from connector
)

select * from fields