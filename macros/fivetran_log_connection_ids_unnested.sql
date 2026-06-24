{% macro fivetran_log_connection_ids_unnested() -%}

{{ adapter.dispatch('fivetran_log_connection_ids_unnested', 'fivetran_log') () }}

{%- endmacro %}

{% macro default__fivetran_log_connection_ids_unnested() %}
{# postgres #}
    select
        transformation_logs.transformation_id,
        connection_id_raw as connection_id
    from transformation_logs
    cross join lateral jsonb_array_elements_text(
        (transformation_logs.full_run_log::jsonb) -> 'schedule' -> 'integrations'
    ) as unnested_integrations(connection_id_raw)

{% endmacro %}

{% macro snowflake__fivetran_log_connection_ids_unnested() %}

    select
        transformation_logs.transformation_id,
        flattened_integration.value::varchar as connection_id
    from transformation_logs,
    lateral flatten(input => try_parse_json(transformation_logs.full_run_log):schedule:integrations) flattened_integration

{% endmacro %}

{% macro bigquery__fivetran_log_connection_ids_unnested() %}

    select
        transformation_logs.transformation_id,
        connection_id
    from transformation_logs
    cross join unnest(json_extract_string_array(transformation_logs.full_run_log, '$.schedule.integrations')) as connection_id

{% endmacro %}

{% macro redshift__fivetran_log_connection_ids_unnested() %}
{# Redshift has no native lateral unnest for JSON arrays, so we iterate array indices with a generated
   numbers table. The digit cross join below produces 0-99, capping connections per transformation job
   at 100. Jobs referencing more than 100 connections have the overflow silently dropped. As of 06/2026
   the largest observed Redshift job referenced 32 connections, so 100 leaves comfortable headroom. If
   this cap is ever hit, extend the generator (e.g. add a hundreds digit). See DECISIONLOG.md. #}
    select
        transformation_logs.transformation_id,
        json_extract_array_element_text(
            json_extract_path_text(transformation_logs.full_run_log, 'schedule', 'integrations'),
            numbers.n,
            true
        ) as connection_id
    from transformation_logs
    cross join (
        select (tens.n * 10 + ones.n) as n
        from (
            select 0 as n union all select 1 union all select 2 union all select 3 union all select 4
            union all select 5 union all select 6 union all select 7 union all select 8 union all select 9
        ) tens
        cross join (
            select 0 as n union all select 1 union all select 2 union all select 3 union all select 4
            union all select 5 union all select 6 union all select 7 union all select 8 union all select 9
        ) ones
    ) numbers
    where numbers.n < json_array_length(
        json_extract_path_text(transformation_logs.full_run_log, 'schedule', 'integrations'), true
    )
    and json_extract_array_element_text(
        json_extract_path_text(transformation_logs.full_run_log, 'schedule', 'integrations'),
        numbers.n,
        true
    ) != ''

{% endmacro %}

{% macro sqlserver__fivetran_log_connection_ids_unnested() %}

    select
        transformation_logs.transformation_id,
        integration_values.[value] as connection_id
    from transformation_logs
    cross apply openjson(json_query(transformation_logs.full_run_log, '$.schedule.integrations')) integration_values

{% endmacro %}

{% macro spark__fivetran_log_connection_ids_unnested() %}
{# databricks and spark #}
    select
        transformation_logs.transformation_id,
        connection_id
    from transformation_logs
    lateral view explode(
        from_json(
            get_json_object(transformation_logs.full_run_log, '$.schedule.integrations'),
            'array<string>'
        )
    ) as connection_id

{% endmacro %}
