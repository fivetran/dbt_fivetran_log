{{ config(enabled=var('fivetran_platform_using_destination_membership', True)) }}

with base as (
    
    select * from {{ var('destination_membership') }}
),

fields as (

    select
        destination_id,
        user_id,
        cast(activated_at as {{ dbt.type_timestamp() }}) as activated_at,
        cast(joined_at as {{ dbt.type_timestamp() }}) as joined_at,
        role as destination_role
    from base
)

select * 
from fields
