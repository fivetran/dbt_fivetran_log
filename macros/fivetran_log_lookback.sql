{% macro fivetran_log_lookback(from_date, datepart='day', interval=7, default_start_date='2010-01-01') %}

{{ adapter.dispatch('fivetran_log_lookback', 'fivetran_log') (from_date, datepart='day', interval=7, default_start_date='2010-01-01') }}

{%- endmacro %}

{% macro default__fivetran_log_lookback(from_date, datepart='day', interval=7, default_start_date='2010-01-01')  %}

    coalesce(
        (select {{ dbt.dateadd(datepart=datepart, interval=-interval, from_date_or_timestamp=from_date) }} 
            from {{ this }}), 
        {{ "'" ~ default_start_date ~ "'" }}
        )

{% endmacro %}