{% macro get_connector_columns() %}

{% set columns = [
    {"name": "_fivetran_deleted", "datatype": "boolean"},
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "connecting_user_id", "datatype": dbt.type_string()},
    {"name": "connector_id", "datatype": dbt.type_string()},
    {"name": "connector_name", "datatype": dbt.type_string()},
    {"name": "connector_type", "datatype": dbt.type_string()},
    {"name": "connector_type_id", "datatype": dbt.type_string()},
    {"name": "destination_id", "datatype": dbt.type_string()},
    {"name": "paused", "datatype": "boolean"},
    {"name": "service_version", "datatype": dbt.type_int()},
    {"name": "signed_up", "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
