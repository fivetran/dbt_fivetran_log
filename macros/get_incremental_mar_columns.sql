{% macro get_incremental_mar_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "connector_id", "datatype": dbt.type_string()},
    {"name": "connector_name", "datatype": dbt.type_string()},
    {"name": "destination_id", "datatype": dbt.type_string()},
    {"name": "free_type", "datatype": dbt.type_string()},
    {"name": "measured_date", "datatype": dbt.type_timestamp()},
    {"name": "schema_name", "datatype": dbt.type_string()},
    {"name": "sync_type", "datatype": dbt.type_string()},
    {"name": "table_name", "datatype": dbt.type_string()},
    {"name": "incremental_rows", "datatype": dbt.type_int()},
    {"name": "updated_at", "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}