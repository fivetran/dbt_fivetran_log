{% macro get_audit_trail_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "action", "datatype": dbt.type_string()},
    {"name": "captured_at", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "interaction_method", "datatype": dbt.type_string()},
    {"name": "new_values", "datatype": dbt.type_string()},
    {"name": "old_values", "datatype": dbt.type_string()},
    {"name": "primary_resource_id", "datatype": dbt.type_string()},
    {"name": "primary_resource_type", "datatype": dbt.type_string()},
    {"name": "secondary_resource_id", "datatype": dbt.type_string()},
    {"name": "secondary_resource_type", "datatype": dbt.type_string()},
    {"name": "user_id", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
