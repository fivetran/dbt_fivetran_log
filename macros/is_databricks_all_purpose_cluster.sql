{% macro is_databricks_all_purpose_cluster() %}
{{ return(adapter.dispatch('is_databricks_all_purpose_cluster', 'fivetran_log') ()) }}
{% endmacro %}


{% macro default__is_databricks_all_purpose_cluster() -%}
    {% if target.type in ('databricks') %}
        {% set re = modules.re %}
        {% set path_match = target.http_path %}
        {% set regex_pattern = "sql/protocol" %}
        {% set match_result = re.search(regex_pattern, path_match) %}
        {{ return(True) if match_result else return(False) }}
    {% else %}
        {{ return(False) }}
    {% endif %}
{% endmacro %}
