{% macro get_log_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "connector_id", "datatype": dbt.type_string()},
    {"name": "event", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "message_data", "datatype": dbt.type_string()},
    {"name": "message_event", "datatype": dbt.type_string()},
    {"name": "sync_id", "datatype": dbt.type_string()},
    {"name": "time_stamp", "datatype": dbt.type_timestamp()},
    {"name": "transformation_id", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}