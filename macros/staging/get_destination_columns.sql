{% macro get_destination_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "account_id", "datatype": dbt.type_string()},
    {"name": "created_at", "datatype": dbt.type_timestamp()},
    {"name": "deployment_type", "datatype": dbt.type_string()},
    {"name": "destination_type", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "is_active", "datatype": dbt.type_boolean()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "region", "datatype": dbt.type_string()},
    {"name": "type", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}