{% macro is_incremental_compatible() %}
{{ return(adapter.dispatch('is_incremental_compatible', 'fivetran_log') ()) }}
{% endmacro %}

{% macro default__is_incremental_compatible() -%}
    {% set is_compatible_target = target.type in ('bigquery','snowflake','postgres','redshift','sqlserver','databricks') %}
    {{ return(is_compatible_target) }}
{% endmacro %}