{% macro is_incremental_compatible() %}
{{ return(adapter.dispatch('is_incremental_compatible', 'fivetran_log') ()) }}
{% endmacro %}

{% macro default__is_incremental_compatible() -%}
    {{ return(False) }}
{% endmacro %}

{% macro bigquery__is_incremental_compatible() -%}
    {{ return(True) }}
{% endmacro %}

{% macro snowflake__is_incremental_compatible() -%}
    {{ return(True) }}
{% endmacro %}

{% macro postgres__is_incremental_compatible() -%}
    {{ return(True) }}
{% endmacro %}

{% macro redshift__is_incremental_compatible() -%}
    {{ return(True) }}
{% endmacro %}

{% macro sqlserver__is_incremental_compatible() -%}
    {{ return(True) }}
{% endmacro %}

{% macro databricks__is_incremental_compatible() -%}
    {{ return(True) }}
{% endmacro %}