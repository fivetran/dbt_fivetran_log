{%- macro fivetran_day_of_month(date) -%}
    {{ return(adapter.dispatch('fivetran_day_of_month', 'fivetran_log') (date)) }}
{%- endmacro %}

{%- macro default__day_of_month(date) -%}
    {{ fivetran_log.fivetran_date_part('day', date) }}
{%- endmacro %}

{%- macro redshift__day_of_month(date) -%}
    cast({{ fivetran_log.fivetran_date_part('day', date) }} as {{ dbt.type_bigint() }})
{%- endmacro %}