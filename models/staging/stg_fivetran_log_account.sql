with account as (
    
    {% for source_destination in var('source_destinations')  %}
    select 
        *,
        '{{ source_destination }}' as source_destination
    from {{ source( source_destination, 'account') }} 
    {% if not loop.last -%} union all {%- endif %}
    {% endfor %}
),

fields as (

    select
        id as account_id,
        country,
        created_at,
        name as account_name,
        status,
        source_destination
        
    from account
)

select * from fields