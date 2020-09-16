{%- macro type_string() -%}
  {{ adapter.dispatch('type_string', packages = fivetran_log._get_utils_namespaces()) () }}
{%- endmacro -%}

{%- macro default__type_string() -%}
    string
{%- endmacro -%}

{%- macro redshift__type_string() -%}
    varchar
{%- endmacro -%}

{%- macro snowflake__type_string() -%}
    varchar
{%- endmacro -%}