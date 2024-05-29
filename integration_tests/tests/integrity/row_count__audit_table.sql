
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with end_model as (
    select 
        connector_id, 
        destination_id,
        schema_name,
        table_name, 
        count(*) as row_count
    from {{ ref('fivetran_platform__audit_table') }}
    group by connector_id, destination_id, schema_name, table_name
),

staging_model as (
    select
        logs.connector_id, 
        connectors.destination_id,
        {{ fivetran_log.fivetran_log_json_parse(string='logs.message_data', string_path=['schema']) }} as schema_name,
        {{ fivetran_log.fivetran_log_json_parse(string='logs.message_data', string_path=['table']) }} as table_name,
        count(*) as row_count
    from {{ ref('stg_fivetran_platform__log') }} as logs
    left join {{ ref('stg_fivetran_platform__connector') }} as connectors
        on connectors.connector_id = logs.connector_id
    where event_subtype in ('write_to_table_start')
    group by logs.connector_id, connectors.destination_id, {{ fivetran_log.fivetran_log_json_parse(string='logs.message_data', string_path=['schema']) }}, {{ fivetran_log.fivetran_log_json_parse(string='logs.message_data', string_path=['table']) }}
)

select 
    end_model.connector_id,
    end_model.destination_id,
    end_model.schema_name,
    end_model.table_name,
    end_model.row_count as end_model_row_count,
    staging_model.row_count as staging_model_row_count
from end_model
left join staging_model
    on end_model.connector_id = staging_model.connector_id
    and end_model.destination_id = staging_model.destination_id
    and end_model.schema_name = staging_model.schema_name
    and end_model.table_name = staging_model.table_name
where staging_model.row_count != end_model.row_count