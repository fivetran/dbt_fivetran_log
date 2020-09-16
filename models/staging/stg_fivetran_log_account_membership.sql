with account_membership as (
    
    {% if var('unioning_multiple_destinations', false) is true %}
    {{ union_source_tables('account_membership') }}

    {% else %}
    select * from {{ var('account_membership') }}
    
    {% endif %}

),

fields as (

    select
        account_id,
        user_id,
        activated_at,
        joined_at,
        role as account_role,
        {% if var('unioning_multiple_destinations', false) is true -%}
        {{ string_agg( 'destination_database', "', '") }} 
        {% else -%}
        {{ "'" ~ var('fivetran_log_database', target.database) ~ "'" }} 
        {%- endif %} as destination_databases
        
    from account_membership
    group by 1,2,3,4,5
    
)

select * from fields