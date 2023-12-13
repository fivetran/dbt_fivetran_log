{% macro fivetran_log_json_extract(string, string_path) -%}

{{ adapter.dispatch('fivetran_log_json_extract', 'fivetran_utils') (string, string_path) }}

{%- endmacro %}

{% macro default__fivetran_log_json_extract(string, string_path) %}

  json_extract_path_text({{string}}, {{ "'" ~ string_path ~ "'" }} )
 
{% endmacro %}

{% macro snowflake__fivetran_log_json_extract(string, string_path) %}

  json_extract_path_text(try_parse_json( {{string}} ), {{ "'" ~ string_path ~ "'" }} )

{% endmacro %}

{% macro redshift__fivetran_log_json_extract(string, string_path) %}

  case when is_valid_json( {{string}} ) then json_extract_path_text({{string}}, {{ "'" ~ string_path ~ "'" }} ) else null end
 
{% endmacro %}

{% macro bigquery__fivetran_log_json_extract(string, string_path) %}

  json_extract_scalar({{string}}, {{ "'$." ~ string_path ~ "'" }} )

{% endmacro %}

{% macro postgres__fivetran_log_json_extract(string, string_path) %}

  {{string}}::json->>{{"'" ~ string_path ~ "'" }}

{% endmacro %}

{% macro spark__fivetran_log_json_extract(string, string_path) %}

    get_json_object({{string}}, '$.{{string_path}}')

{% endmacro %}