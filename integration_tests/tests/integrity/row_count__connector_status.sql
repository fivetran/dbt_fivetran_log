
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with end_model as (
    select 
        connection_id,
        connection_name,
        connection_type,
        destination_id,
        set_up_at,
        count(*) as row_count
    from {{ ref('fivetran_platform__connection_status') }}
    group by connection_id, connection_name, connection_type, destination_id, set_up_at
),

staging_model as (
    select
        connection_id,
        connection_name,
        connection_type,
        destination_id,
        set_up_at,
        count(*) as row_count
    from {{ ref('stg_fivetran_platform__connection') }}
    group by connection_id, connection_name, connection_type, destination_id, set_up_at
)

select 
    end_model.connection_id,
    end_model.connection_name,
    end_model.connection_type,
    end_model.destination_id,
    end_model.set_up_at,
    end_model.row_count as end_model_row_count,
    staging_model.row_count as staging_model_row_count
from end_model
left join staging_model
    on end_model.connection_id = staging_model.connection_id
    and end_model.destination_id = staging_model.destination_id
where staging_model.row_count != end_model.row_count