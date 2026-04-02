{{ config(enabled=var('fivetran_platform_using_user', True)) }}

with base as (

    select * 
    from {{ var('user') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('fivetran_platform', 'user')),
                staging_columns=get_user_columns()
            )
        }}
    from base
),

final as (

    select
        id as user_id,
        cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
        email,
        email_disabled as has_disabled_email_notifications,
        family_name as last_name,
        given_name as first_name,
        phone,
        verified as is_verified
    from fields
)

select * 
from final
