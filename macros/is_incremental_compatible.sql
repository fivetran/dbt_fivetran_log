{% macro is_incremental_compatible() %}
    {% set is_compatible_target = target.type in ('bigquery','snowflake','postgres','redshift','sqlserver','databricks') %}
    {{ return(is_compatible_target) }}
{% endmacro %}