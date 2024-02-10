{% macro fivetran_log_json_extract(string, string_path) -%}

{{ adapter.dispatch('fivetran_log_json_extract', 'fivetran_log') (string, string_path) }}

{%- endmacro %}

{% macro default__fivetran_log_json_extract(string, string_path) %}

  {{ fivetran_utils.json_parse(string=string, string_path=string_path) }}

{% endmacro %}

{% macro snowflake__json_extract(string, string_path) %}

  json_parse(string=try_parse_json( {{string}} ), string_path=string_path )

{% endmacro %}

{% macro redshift__fivetran_log_json_extract(string, string_path) %}

  case when is_valid_json({{ string }}) 
  then {{ fivetran_utils.json_parse(string=string, string_path=string_path) }}
  else null end

{% endmacro %}