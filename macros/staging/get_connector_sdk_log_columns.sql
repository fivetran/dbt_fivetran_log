{% macro get_connector_sdk_log_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "connection_id", "datatype": dbt.type_string()},
    {"name": "event_time", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "level", "datatype": dbt.type_string()},
    {"name": "message", "datatype": dbt.type_string()},
    {"name": "message_origin", "datatype": dbt.type_string()},
    {"name": "sync_id", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
