{% macro get_connection_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "connecting_user_id", "datatype": dbt.type_string()},
    {"name": "connection_id", "datatype": dbt.type_string()},
    {"name": "connection_name", "datatype": dbt.type_string()},
    {"name": "connection_type", "datatype": dbt.type_string()},
    {"name": "connection_type_id", "datatype": dbt.type_string()},
    {"name": "connector_id", "datatype": dbt.type_string()},
    {"name": "connector_name", "datatype": dbt.type_string()},
    {"name": "connector_type", "datatype": dbt.type_string()},
    {"name": "connector_type_id", "datatype": dbt.type_string()},
    {"name": "destination_id", "datatype": dbt.type_string()},
    {"name": "paused", "datatype": dbt.type_boolean()},
    {"name": "service_version", "datatype": dbt.type_int()},
    {"name": "signed_up", "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
