
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with end_model as (
    select 
        connection_id, 
        table_name,
        count(*) as row_count
    from {{ ref('fivetran_platform__schema_changelog') }}
    group by connection_id, table_name
),

staging_model as (
    select
        connection_id, 
        case 
            when event_subtype = 'alter_table' then {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['table']) }} 
            when event_subtype = 'create_table' then {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['name']) }}
        end as table_name,
        count(*) as row_count
    from {{ ref('stg_fivetran_platform__log') }}
    where event_subtype in ('create_table', 'alter_table', 'create_schema', 'change_schema_config')
    group by connection_id, case when event_subtype = 'alter_table' then {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['table']) }} when event_subtype = 'create_table' then {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['name']) }} end
)

select 
    end_model.connection_id,
    end_model.table_name,
    end_model.row_count as end_model_row_count,
    staging_model.row_count as staging_model_row_count
from end_model
left join staging_model
    on end_model.connection_id = staging_model.connection_id
    and end_model.table_name = staging_model.table_name
where staging_model.row_count != end_model.row_count