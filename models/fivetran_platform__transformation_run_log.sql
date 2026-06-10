{{ config(enabled=var('fivetran_platform_using_transformations', true))}} 

with logs as (

    select *
    from {{ ref('stg_fivetran_platform__log') }}

),

transformation_runs as (

    select *
    from {{ ref('stg_fivetran_platform__transformation_runs') }}

),

destinations as (

    select *
    from {{ ref('stg_fivetran_platform__destination') }}

),

connections as (

    select *
    from {{ ref('stg_fivetran_platform__connection') }}

),

transformation_logs as (

    select
        event_subtype,
        message_data as full_run_log,
        {{ fivetran_log.fivetran_log_json_parse(string="message_data", string_path=["id"]) }} as transformation_id,
        cast({{ fivetran_log.fivetran_log_json_parse(string="message_data", string_path=["startTime"]) }} as {{ dbt.type_timestamp() }}) as started_at,
        cast({{ fivetran_log.fivetran_log_json_parse(string="message_data", string_path=["endTime"]) }} as {{ dbt.type_timestamp() }}) as ended_at,
        {{ fivetran_log.fivetran_log_json_parse(string="message_data", string_path=["name"]) }} as transformation_name,
        {{ fivetran_log.fivetran_log_json_parse(string="message_data", string_path=["transformationType"]) }} as transformation_type,
        {{ fivetran_log.fivetran_log_json_parse(string="message_data", string_path=["result", "stepResults", 0, "success"]) }} as step_success,
        cast({{ fivetran_log.fivetran_log_json_parse(string="message_data", string_path=["result", "stepResults", 0, "successfulModelRuns"]) }} as {{ dbt.type_int() }}) as successful_model_runs,
        cast({{ fivetran_log.fivetran_log_json_parse(string="message_data", string_path=["result", "stepResults", 0, "failedModelRuns"]) }} as {{ dbt.type_int() }}) as failed_model_runs
    from logs
    where event_subtype like 'transformation%'
        and event_subtype != 'transformation_start'
    --transformation failure and success events capture start/end datetimes so the start event is redundant
),

connection_ids_unnested as (

    {{ fivetran_log.fivetran_log_connection_ids_unnested() }}

),

job_destinations as (

    select
        transformation_runs.job_id,
        transformation_runs.destination_id,
        max(transformation_runs.job_name) as job_name,
        max(transformation_runs.project_type) as project_type,
        max(destinations.destination_name) as destination_name
    from transformation_runs
    left join destinations
        on destinations.destination_id = transformation_runs.destination_id
    group by transformation_runs.job_id, transformation_runs.destination_id

),

distinct_connection_ids as (

    select distinct
        connection_ids_unnested.transformation_id,
        cast(connection_ids_unnested.connection_id as {{ dbt.type_string() }}) as connection_id,
        cast(connections.connection_name as {{ dbt.type_string() }}) as connection_name
    from connection_ids_unnested
    left join connections
        on connections.connection_id = connection_ids_unnested.connection_id

),

connection_aggregates as (

    select
        transformation_id,
        {{ fivetran_utils.string_agg("connection_id", "', '") }} as connection_ids,
        {{ fivetran_utils.string_agg("connection_name", "', '") }} as connection_names
    from distinct_connection_ids
    group by transformation_id

),

job_connections as (

    select
        job_destinations.job_id,
        job_destinations.destination_id,
        job_destinations.destination_name,
        cast(connections.connection_id as {{ dbt.type_string() }}) as fallback_connection_id,
        cast(connections.connection_name as {{ dbt.type_string() }}) as fallback_connection_name
    from job_destinations
    left join connections
        on job_destinations.project_type = 'QUICKSTART'
        and job_destinations.job_name like '%/%'
        and connections.connection_name = {{ dbt.split_part(string_text='job_destinations.job_name', delimiter_text="'/'", part_number=2) }}
        and connections.destination_id = job_destinations.destination_id

),

with_duration as (

    select
        transformation_logs.started_at,
        transformation_logs.ended_at,
        transformation_logs.transformation_id,
        transformation_logs.transformation_name,
        transformation_logs.transformation_type,
        transformation_logs.step_success,
        transformation_logs.successful_model_runs,
        transformation_logs.failed_model_runs,
        transformation_logs.full_run_log,
        job_connections.destination_id,
        job_connections.destination_name,
        coalesce(connection_aggregates.connection_ids, job_connections.fallback_connection_id) as connection_ids,
        coalesce(connection_aggregates.connection_names, job_connections.fallback_connection_name) as connection_names,
        {{ dbt.datediff('started_at', 'ended_at', 'second') }} as duration_seconds
    from transformation_logs
    left join job_connections
        on job_connections.job_id = transformation_logs.transformation_id
    left join connection_aggregates
        on connection_aggregates.transformation_id = transformation_logs.transformation_id

),

final as (

    select
        started_at,
        ended_at,
        duration_seconds,
        {% if target.type == 'sqlserver' %}
        right('00' + cast(duration_seconds / 3600 as varchar(10)), 2) + ':' +
        right('00' + cast((duration_seconds % 3600) / 60 as varchar(10)), 2) + ':' +
        right('00' + cast(duration_seconds % 60 as varchar(10)), 2) as duration,
        {% else %}
        lpad(cast(floor(duration_seconds / 3600.0) as {{ dbt.type_string() }}), 2, '0') || ':' ||
        lpad(cast(floor(mod(cast(duration_seconds as {{ dbt.type_int() }}), 3600) / 60.0) as {{ dbt.type_string() }}), 2, '0') || ':' ||
        lpad(cast(mod(cast(duration_seconds as {{ dbt.type_int() }}), 60) as {{ dbt.type_string() }}), 2, '0') as duration,
        {% endif %}
        destination_id,
        destination_name,
        connection_ids,
        connection_names,
        transformation_name,
        transformation_id,
        transformation_type,
        successful_model_runs,
        failed_model_runs,
        case
            when step_success = 'true' then 'transformation_succeeded'
            when step_success = 'false'
                and successful_model_runs > 0
                and failed_model_runs > 0
                then 'transformation_partially_succeeded'
            else 'transformation_failed'
        end as transformation_status,
        full_run_log
    from with_duration

)

select *
from final
