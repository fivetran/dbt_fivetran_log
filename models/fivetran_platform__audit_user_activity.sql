with logs as (

    select 
        *,
        {{ fivetran_utils.json_parse(string='message_data', string_path=['actor']) }} as actor_email
    from {{ ref('stg_fivetran_platform__log') }}
    where lower(message_data) like '%actor%'
),

user_logs as (

    select *
    from logs
    where actor_email is not null 
        and lower(actor_email) != 'fivetran'
),

connector as (

    select *
    from {{ ref('stg_fivetran_platform__connector') }}
),

destination as (

    select *
    from {{ ref('stg_fivetran_platform__destination') }}
),

{%- if var('fivetran_platform_using_user', true) %}
users as (

    select *
    from {{ ref('stg_fivetran_platform__user') }}
),

    {%- if var('fivetran_platform_using_destination_membership', true) %}
    destination_membership as (

        select *
        from {{ ref('stg_fivetran_platform__destination_membership') }}
    ),
    {% endif -%}

{% endif -%}

final as (

    select
        {{ dbt.date_trunc('day', 'user_logs.created_at') }} as date_day,
        
        {% if target.type != 'sqlserver' -%}
            {{ dbt_date.day_name('user_logs.created_at') }} as day_name,
            {{ dbt_date.day_of_month('user_logs.created_at') }} as day_of_month,
        {% else -%} 
            format(cast(user_logs.created_at as date), 'ddd') as day_name,
            day(user_logs.created_at) as day_of_month,
        {% endif -%} 
        
        user_logs.created_at as occurred_at,
        destination.destination_name,
        destination.destination_id,
        connector.connector_name,
        connector.connector_id,
        user_logs.actor_email as email,
{%- if var('fivetran_platform_using_user', true) %}
        users.first_name,
        users.last_name,
        users.user_id,
    {%- if var('fivetran_platform_using_destination_membership', true) %}
        destination_membership.destination_role,
    {% endif -%}
{% endif -%}

        user_logs.event_type, -- should always be INFO for user-triggered actions but include just in case
        user_logs.event_subtype,
        user_logs.message_data,
        user_logs.log_id

    from user_logs
    left join connector
        on user_logs.connector_id = connector.connector_id
    left join destination
        on connector.destination_id = destination.destination_id

{%- if var('fivetran_platform_using_user', true) %}
    left join users 
        on lower(users.email) = lower(user_logs.actor_email)

    {%- if var('fivetran_platform_using_destination_membership', true) %}
    left join destination_membership
        on destination.destination_id = destination_membership.destination_id
        and users.user_id = destination_membership.user_id

    {% endif -%}
{% endif -%}

)

select *
from final
