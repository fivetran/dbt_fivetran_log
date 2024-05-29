{% macro is_databricks_all_purpose(target) %}
    {% if target.type in ('databricks') %}
        {% set re = modules.re %}
        {% set path_match = target.http_path %}
        {% set regex_pattern = "sql/protocol" %}
        {% set match_result = re.search(regex_pattern, path_match) %}
        {% if match_result %}
            {{ return(True) }}
        {% else %}
            {{ return(False) }}
        {% endif %}
    {% else %}
        {{ return(False) }}
    {% endif %}
{% endmacro %}