{{ config(enabled=var('fivetran_platform_using_transformations', True)) }}

with base as (
    
    select * 
    from {{ var('transformation') }}
),

fields as (

    select
        id as transformation_id,
        cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
        created_by_id as created_by_user_id,
        destination_id,
        name as transformation_name,
        paused as is_paused,
        script,
        trigger_delay,
        trigger_interval,
        trigger_type
    from base
)

select * 
from fields
where transformation_id is not null