{% macro fivetran_log_json_parse(string, string_path) -%}

{{ adapter.dispatch('fivetran_log_json_parse', 'fivetran_log') (string, string_path) }}

{%- endmacro %}

{% macro default__fivetran_log_json_parse(string, string_path) %}

  {{ fivetran_log.fivetran_log_json_parse(string=string, string_path=string_path) }}

{% endmacro %}

{% macro snowflake__json_extract(string, string_path) %}

  case when try_parse_json({{ string }}) is not null
  then {{ fivetran_log.fivetran_log_json_parse(string=string, string_path=string_path) }}
  else null end

{% endmacro %}

{% macro redshift__fivetran_log_json_parse(string, string_path) %}

  case when is_valid_json({{ string }}) 
  then {{ fivetran_log.fivetran_log_json_parse(string=string, string_path=string_path) }}
  else null end

{% endmacro %}