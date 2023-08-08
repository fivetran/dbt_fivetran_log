{{ config(enabled=var('fivetran_platform_using_user', True)) }}

with base as (

    select * 
    from {{ var('user') }}
),

fields as (

    select
        id as user_id,
        cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
        email,
        email_disabled as has_disabled_email_notifications,
        family_name as last_name,
        given_name as first_name,
        phone,
        verified as is_verified
    from base
)

select * 
from fields
