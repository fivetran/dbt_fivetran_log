{% macro get_transformation_runs_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "destination_id", "datatype": dbt.type_string()},
    {"name": "free_type", "datatype": dbt.type_string()},
    {"name": "job_id", "datatype": dbt.type_string()},
    {"name": "job_name", "datatype": dbt.type_string()},
    {"name": "measured_date", "datatype": dbt.type_timestamp()},
    {"name": "model_runs", "datatype": dbt.type_int()},
    {"name": "project_type", "datatype": dbt.type_string()},
    {"name": "updated_at", "datatype": dbt.type_timestamp()}
] %}

{{ return(columns) }}

{% endmacro %}
