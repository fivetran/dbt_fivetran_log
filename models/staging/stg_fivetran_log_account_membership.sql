with account_membership as (
    
    {% for source_destination in var('source_destinations')  %}
    select 
        *,
        '{{ source_destination }}' as source_destination
    from {{ source( source_destination, 'account_membership') }} 
    {% if not loop.last -%} union all {%- endif %}
    {% endfor %}

),

fields as (

    select
        account_id,
        user_id,
        activated_at,
        joined_at,
        role as account_role,
        source_destination
        
    from account_membership
)

select * from fields