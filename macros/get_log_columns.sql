{% macro get_log_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt_utils.type_timestamp()},
    {"name": "connector_id", "datatype": dbt_utils.type_string()},
    {"name": "event", "datatype": dbt_utils.type_string()},
    {"name": "id", "datatype": dbt_utils.type_string()},
    {"name": "message_data", "datatype": dbt_utils.type_string()},
    {"name": "message_event", "datatype": dbt_utils.type_string()},
    {"name": "process_id", "datatype": dbt_utils.type_string()},
    {"name": "sequence_number", "datatype": dbt_utils.type_int()},
    {"name": "sync_id", "datatype": dbt_utils.type_string()},
    {"name": "time_stamp", "datatype": dbt_utils.type_timestamp()},
    {"name": "transformation_id", "datatype": dbt_utils.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}