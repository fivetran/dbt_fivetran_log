{% macro is_databricks_sql_warehouse() %}
    {% if target.type in ('databricks') %}
        {% set re = modules.re %}
        {% set path_match = target.http_path %}
        {% set regex_pattern = "sql/protocol" %}
        {% set match_result = re.search(regex_pattern, path_match) %}
        {{ return(re.search(regex_pattern, path_match)) }}
    {% else %}
        {{ return(False) }}
    {% endif %}
{% endmacro %}
