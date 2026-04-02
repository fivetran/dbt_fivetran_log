{% macro fivetran_log_json_parse_dev(string, string_path) -%}

{{ adapter.dispatch('fivetran_log_json_parse_dev', 'fivetran_log') (string, string_path) }}

{%- endmacro %}

{% macro default__fivetran_log_json_parse_dev(string, string_path) %}

  {{ fivetran_utils.json_parse(string=string, string_path=string_path) }}

{% endmacro %}

{% macro snowflake__fivetran_log_json_parse_dev(string, string_path) %}

  try_parse_json({{ string }}) {%- for s in string_path -%}{% if s is number %}[{{ s }}]{% else %}['{{ s }}']{% endif %}{%- endfor -%}

{% endmacro %}

{% macro redshift__fivetran_log_json_parse_dev(string, string_path) %}

  nullif(
    json_extract_path_text(
      {{ string }}, 
      {%- for s in string_path -%}'{{ s }}'{%- if not loop.last -%},{%- endif -%}{%- endfor -%}, 
      true ) -- this flag sets null_if_invalid=true
    , '')

{% endmacro %}

{% macro postgres__fivetran_log_json_parse_dev(string, string_path) %}

  {# Removed regex check from postgres__fivetran_log_json_parse #}
  case when {{ string }} is not null
    then {{ string }} #>> '{ {%- for s in string_path -%}{{ s }}{%- if not loop.last -%},{%- endif -%}{%- endfor -%} }'
    else null end

{% endmacro %}

{% macro sqlserver__fivetran_log_json_parse_dev(string, string_path) %}

  {# Removed regex check from sqlserver__fivetran_log_json_parse #}
  case when {{ string }} is not null
    then json_value({{ string }}, '$.{%- for s in string_path -%}{{ s }}{%- if not loop.last -%}.{%- endif -%}{%- endfor -%} ')
    else null end

{% endmacro %}