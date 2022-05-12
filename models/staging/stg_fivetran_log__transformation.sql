{{ config(enabled=var('fivetran_log_using_transformations', True)) }}

with transformation as (
    
    select * 
    from {{ var('transformation') }}
),

fields as (

    select
        id as transformation_id,
        cast(created_at as {{ dbt_utils.type_timestamp() }}) as created_at,
        created_by_id as created_by_user_id,
        destination_id,
        name as transformation_name,
        paused as is_paused,
        script,
        trigger_delay,
        trigger_interval,
        trigger_type
    from transformation
)

select * 
from fields
where transformation_id is not null