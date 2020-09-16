with fivetran_user as (
    
    {% if var('unioning_multiple_destinations', false) is true %}
    {{ union_source_tables('user') }}

    {% else %}
    select * from {{ var('user') }}
    
    {% endif %}
),

fields as (

    select
        id as user_id,
        created_at,
        email,
        email_disabled as has_disabled_email_notifications,
        family_name as last_name,
        given_name as first_name,
        phone,
        verified as is_verified,

        {% if var('unioning_multiple_destinations', false) is true -%}
        {{ string_agg( 'destination_database', "', '") }} 
        {% else -%}
        {{ "'" ~ var('fivetran_log_database', target.database) ~ "'" }} 
        {%- endif %} as destination_databases
        
    from fivetran_user
    group by 1,2,3,4,5,6,7,8
)

select * from fields