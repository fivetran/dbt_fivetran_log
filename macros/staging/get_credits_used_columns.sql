{% macro get_credits_used_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "credits_consumed", "datatype": dbt.type_int()},
    {"name": "destination_id", "datatype": dbt.type_string()},
    {"name": "measured_month", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}