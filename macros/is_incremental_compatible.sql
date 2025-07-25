{% macro is_incremental_compatible() %}
    {{ return(target.type in ('bigquery','snowflake','postgres','redshift','sqlserver','databricks')) }}
{% endmacro %}