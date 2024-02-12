{% macro fivetran_log_json_parse(string, string_path) -%}

{{ adapter.dispatch('fivetran_log_json_parse', 'fivetran_log') (string, string_path) }}

{%- endmacro %}

{% macro default__fivetran_log_json_parse(string, string_path) %}

  {{ fivetran_log.fivetran_log_json_parse(string=string, string_path=string_path) }}

{% endmacro %}

{% macro snowflake__json_extract(string, string_path) %}

  try_parse_json( {{string}} ) {%- for s in string_path -%}{% if s is number %}[{{ s }}]{% else %}['{{ s }}']{% endif %}{%- endfor -%}

{% endmacro %}

{% macro redshift__fivetran_log_json_parse(string, string_path) %}

  {# case when is_valid_json({{ string }}) 
  then {{ fivetran_log.fivetran_log_json_parse(string=string, string_path=string_path) }}
  else null end #}
  json_extract_path_text(
    {{string}}, 
    {%- for s in string_path -%}'{{ s }}'{%- if not loop.last -%},{%- endif -%}{%- endfor -%}, 
    true ) -- this means null_if_invalid=true

{% endmacro %}