{{ config(materialized='view' if target.type=='postgres' else 'ephemeral') }}

-- Purpose is to shift all json parsing to this int model.
select 
    *,
    {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['table']) }} as table_name,
    cast(null as {{ dbt.type_string() }}) as schema_name,
    cast(null as {{ dbt.type_string() }}) as operation_type,
    cast(null as {{ dbt.type_bigint() }}) as row_count
from {{ ref('stg_fivetran_platform__log') }}
where event_subtype in ('sync_start', 'sync_end', 'write_to_table_start', 'write_to_table_end')

union all

select 
    *,
    {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['table']) }} as table_name,
    {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['schema']) }} as schema_name,
    {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['operationType']) }} as operation_type,
    cast ({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['count']) }} as {{ dbt.type_bigint() }}) as row_count
from {{ ref('stg_fivetran_platform__log') }} 
where event_subtype = 'records_modified'