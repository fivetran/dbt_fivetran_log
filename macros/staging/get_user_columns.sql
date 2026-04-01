{% macro get_user_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "created_at", "datatype": dbt.type_timestamp()},
    {"name": "email", "datatype": dbt.type_string()},
    {"name": "email_disabled", "datatype": dbt.type_boolean()},
    {"name": "family_name", "datatype": dbt.type_string()},
    {"name": "given_name", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_string()},
    {"name": "phone", "datatype": dbt.type_string()},
    {"name": "verified", "datatype": dbt.type_boolean()}
] %}

{{ return(columns) }}

{% endmacro %}