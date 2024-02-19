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

{% macro bigquery__fivetran_log_lookback(from_date, datepart='day', interval=7, default_start_date='2010-01-01')  %}

    -- Capture the latest timestamp in a call statement instead of a subquery for optimizing BQ costs on incremental runs
    {%- call statement('max_date', fetch_result=True) -%}
        select {{ from_date }} from {{ this }}
    {%- endcall -%}

    -- load the result from the above query into a new variable
    {%- set query_result = load_result('max_date') -%}

    -- the query_result is stored as a dataframe. Therefore, we want to now store it as a singular value.
    {%- set max_date = query_result['data'][0][0] %}

    coalesce(
        {{ dbt.dateadd(datepart='day', interval=-7, from_date_or_timestamp="'" ~ max_date ~ "'") }}, 
        {{ "'" ~ default_start_date ~ "'" }}
        )

{% endmacro %}