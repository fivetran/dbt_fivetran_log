{% macro is_databricks_sql_warehouse() %}
{{ return(adapter.dispatch('is_databricks_sql_warehouse', 'fivetran_platform') ()) }}
{% endmacro %}


{% macro default__is_databricks_sql_warehouse() -%}
    {% if target.type in ('databricks') %}
        {% set re = modules.re %}
        {% set path_match = target.http_path %}
        {% set regex_pattern = "sql/protocol" %}
        {% set match_result = re.search(regex_pattern, path_match) %}
        {{ return(False) if match_result else return(True) }}
    {% else %}
        {{ return(False) }}
    {% endif %}
{% endmacro %}
