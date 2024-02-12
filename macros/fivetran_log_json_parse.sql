{% macro fivetran_log_json_parse(string, string_path) -%}

{{ adapter.dispatch('fivetran_log_json_parse', 'fivetran_log') (string, string_path) }}

{%- endmacro %}

{% macro default__fivetran_log_json_parse(string, string_path) %}

  {% if fromjson(string, none) is not none %}
    {{ fivetran_utils.json_parse(string=string, string_path=string_path) }}
  {% else %}
    null
  {% endif %}

{% endmacro %}