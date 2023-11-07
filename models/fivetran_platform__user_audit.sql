with logs as (

    select 
        *,
        {{ fivetran_utils.json_parse(string='message_data', string_path=['actor']) }} as actor_email
    from {{ var('log') }}
),

user_logs as (

    select *
    from logs
    where actor_email is not null
),

connector as (

    select *
    from {{ var('connector') }}
),

destination as (

    select *
    from {{ var('destination') }}
),

{%- if var('fivetran_platform_using_user', true) %}
user as (

    select *
    from {{ var('user') }}
),

    {%- if var('fivetran_platform_using_destination_membership', true) %}
    destination_membership as (

        select *
        from {{ var('destination_membership') }}
    ),
    {% endif -%}

{% endif -%}

final as (

    select
        {{ dbt.date_trunc('day', 'user_logs.created_at') }} as date_day,
        {{ dbt_date.day_name('user_logs.created_at') }} as day_name,
        {{ dbt_date.day_of_month('user_logs.created_at') }} as day_of_month,
        destination.destination_name,
        destination.destination_id,
        connector.connector_name,
        connector.connector_id,

{%- if var('fivetran_platform_using_user', true) %}
        user.first_name,
        user.last_name,
    {%- if var('fivetran_platform_using_destination_membership', true) %}
        destination_membership.destination_role,
    {% endif -%}
{% endif -%}

        user_logs.event_type, -- should always be INFO for user-triggered actions
        user_logs.event_subtype,
        user_logs.message_data,
        user_logs.log_id

    from user_logs
    left join connector
        on user_logs.connector_id = connector.connector_id
    left join destination
        on connector.destination_id = destination.destination_id

{%- if var('fivetran_platform_using_user', true) %}
    left join user 
        on lower(user.email) = lower(user_logs.actor_email)

    {%- if var('fivetran_platform_using_destination_membership', true) %}
    left join destination_membership
        on destination.destination_id = destination_membership.destination_id
        and user.user_id = destination_membership.user_id

    {% endif -%}
{% endif -%}

)

select *
from final