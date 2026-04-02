{{ config(enabled=var('fivetran_platform_using_destination_membership', True)) }}

with base as (
    
    select * from {{ var('destination_membership') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('fivetran_platform', 'destination_membership')),
                staging_columns=get_destination_membership_columns()
            )
        }}
    from base
),

final as (

    select
        destination_id,
        user_id,
        cast(activated_at as {{ dbt.type_timestamp() }}) as activated_at,
        cast(joined_at as {{ dbt.type_timestamp() }}) as joined_at,
        role as destination_role
    from fields
)

select * 
from final
