{% macro coalesce_cast(column_list, datatype=dbt.type_string()) -%}
    {{ return(adapter.dispatch('coalesce_cast', 'fivetran_log')(column_list, datatype)) }}
{%- endmacro %}

-- This macro will coalesce all columns in a given list and cast them as the same datatype.
{% macro default__coalesce_cast(column_list, datatype=dbt.type_string()) %}
    coalesce(
    {%- for column in column_list %}
        cast({{ column }} as {{ datatype }}){{ ',' if not loop.last }}
    {% endfor %}
    )
{% endmacro %}