{% macro fivetran_log_json_extract(string, string_path) -%}

{{ adapter.dispatch('fivetran_log_json_extract', 'fivetran_log') (string, string_path) }}

{%- endmacro %}

{% macro default__fivetran_log_json_extract(string, string_path) %}

  {{ fivetran_utils.json_extract(string=string, string_path=string_path) }}

{% endmacro %}

{% macro spark__fivetran_log_json_extract(string, string_path) %}

  {{ fivetran_utils.json_parse(string=string, string_path=string_path) }}

{% endmacro %}
