{% macro get_destination_membership_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "activated_at", "datatype": dbt.type_timestamp()},
    {"name": "destination_id", "datatype": dbt.type_string()},
    {"name": "joined_at", "datatype": dbt.type_timestamp()},
    {"name": "role", "datatype": dbt.type_string()},
    {"name": "user_id", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}