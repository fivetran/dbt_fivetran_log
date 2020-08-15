with account as (
    
    {% if unioning_multiple_destinations is true %}
    {{ union_source_tables('account') }}

    {% else %}
    select * from {{ var('account') }}
    
    {% endif %}
),

fields as (

    select
        id as account_id,
        country,
        created_at,
        name as account_name,
        status,
        {% if unioning_multiple_destinations is true -%}
        {{ string_agg( 'destination_database', "', '") }} 
        {% else -%}
        {{ "'" ~ var('fivetran_log_database', target.database) ~ "'" }} 
        {%- endif %} as destination_databases
        
    from account

    group by 1,2,3,4,5
)

select * from fields