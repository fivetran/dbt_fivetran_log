{% macro convert_to_json(string) -%}

{{ adapter.dispatch('convert_to_json', 'fivetran_log') (string) }}

{%- endmacro %}

{% macro default__convert_to_json(string) %}

  {# Don't do anything #}
  {{ return(string) }}

{% endmacro %}

{% macro postgres__convert_to_json(string) %}

  case when {{ string }} ~ '^\s*[\{].*[\}]?\s*$' then {{ string }}::jsonb else null::jsonb end

{% endmacro %}

{% macro sqlserver__convert_to_json(string) %}

  {# Not actually converting, but setting to null if it's not a json #}
  case when isjson({{ string }}) = 1 then {{ string }} else null end
  
{% endmacro %}