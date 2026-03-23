{% macro get_usage_cost_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "amount", "datatype": dbt.type_numeric()},
    {"name": "destination_id", "datatype": dbt.type_string()},
    {"name": "measured_month", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}