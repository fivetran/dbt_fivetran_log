{{ config(enabled=var('fivetran_platform_using_audit_trail', false)) }}

with audit_trail as (

    select *
    from {{ ref('stg_fivetran_platform__audit_trail') }}
),

connection_ranked as (

    select
        connection_id,
        connection_name,
        row_number() over (
            partition by connection_id
            order by is_deleted asc, set_up_at desc
        ) as nth_connection_record
    from {{ ref('stg_fivetran_platform__connection') }}
),

connection as (

    -- dedupe to one row per connection_id (not unique in staging) so the join doesn't fan out audit events
    select
        connection_id,
        connection_name
    from connection_ranked
    where nth_connection_record = 1
),

destination as (

    select
        destination_id,
        destination_name
    from {{ ref('stg_fivetran_platform__destination') }}
),

account as (

    select
        account_id,
        account_name
    from {{ ref('stg_fivetran_platform__account') }}
),

{% if var('fivetran_platform_using_user', true) %}
users as (

    select
        user_id,
        email,
        first_name,
        last_name
    from {{ ref('stg_fivetran_platform__user') }}
),
{% endif %}

final as (

    select
        audit_trail.unique_audit_trail_key,
        audit_trail.audit_trail_id,
        audit_trail.captured_at,
        audit_trail.user_id,
        {%- if var('fivetran_platform_using_user', true) %}
        actor.email as actor_email,
        actor.first_name as actor_first_name,
        actor.last_name as actor_last_name,
        {% endif %}
        audit_trail.action,
        audit_trail.interaction_method,
        audit_trail.primary_resource_type,
        audit_trail.primary_resource_id,
        coalesce(
            primary_connection.connection_name,
            primary_destination.destination_name,
            primary_account.account_name
            {%- if var('fivetran_platform_using_user', true) %},
            primary_user.email
            {%- endif %}
        ) as primary_resource_name,
        audit_trail.secondary_resource_type,
        audit_trail.secondary_resource_id,
        coalesce(
            secondary_connection.connection_name,
            secondary_destination.destination_name,
            secondary_account.account_name
            {%- if var('fivetran_platform_using_user', true) %},
            secondary_user.email
            {%- endif %}
        ) as secondary_resource_name,
        audit_trail.old_values,
        audit_trail.new_values,
        audit_trail._fivetran_synced

    from audit_trail

{%- if var('fivetran_platform_using_user', true) %}

    -- actor who performed the action
    left join users as actor
        on audit_trail.user_id = actor.user_id
{% endif %}

    -- resolve the primary resource (the main resource the action was performed on) to its name
    left join connection as primary_connection
        on audit_trail.primary_resource_id = primary_connection.connection_id
        and audit_trail.primary_resource_type = 'CONNECTION'
    left join destination as primary_destination
        on audit_trail.primary_resource_id = primary_destination.destination_id
        and audit_trail.primary_resource_type = 'DESTINATION'
    left join account as primary_account
        on audit_trail.primary_resource_id = primary_account.account_id
        and audit_trail.primary_resource_type = 'ACCOUNT'
{%- if var('fivetran_platform_using_user', true) %}
    left join users as primary_user
        on audit_trail.primary_resource_id = primary_user.user_id
        and audit_trail.primary_resource_type = 'USER'
{% endif %}

    -- resolve the secondary resource (if applicable) to its name
    left join connection as secondary_connection
        on audit_trail.secondary_resource_id = secondary_connection.connection_id
        and audit_trail.secondary_resource_type = 'CONNECTION'
    left join destination as secondary_destination
        on audit_trail.secondary_resource_id = secondary_destination.destination_id
        and audit_trail.secondary_resource_type = 'DESTINATION'
    left join account as secondary_account
        on audit_trail.secondary_resource_id = secondary_account.account_id
        and audit_trail.secondary_resource_type = 'ACCOUNT'
{%- if var('fivetran_platform_using_user', true) %}
    left join users as secondary_user
        on audit_trail.secondary_resource_id = secondary_user.user_id
        and audit_trail.secondary_resource_type = 'USER'
{% endif %}
)

select *
from final
