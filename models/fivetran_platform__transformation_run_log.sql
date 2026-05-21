{% if var('fivetran_platform_using_transformations', does_table_exist('transformation_runs')) %}

with transformation_logs as (

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
    from {{ ref('stg_fivetran_platform__log') }}
    where event_subtype like '%transformation%'
        and event_subtype != 'transformation_start'

),

job_destinations as (

    select distinct
        transformation_runs.job_id,
        transformation_runs.destination_id,
        destination.destination_name
    from {{ ref('stg_fivetran_platform__transformation_runs') }} as transformation_runs
    left join {{ ref('stg_fivetran_platform__destination') }} as destination
        on destination.destination_id = transformation_runs.destination_id

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
        transformation_logs.event_subtype,
        transformation_logs.full_run_log,
        job_destinations.destination_id,
        job_destinations.destination_name,
        {{ dbt.datediff('started_at', 'ended_at', 'second') }} as duration_seconds
    from transformation_logs
    left join job_destinations
        on job_destinations.job_id = transformation_logs.transformation_id

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
        lpad(cast(floor((duration_seconds % 3600) / 60.0) as {{ dbt.type_string() }}), 2, '0') || ':' ||
        lpad(cast(duration_seconds % 60 as {{ dbt.type_string() }}), 2, '0') as duration,
        {% endif %}
        destination_id,
        destination_name,
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
        event_subtype,
        full_run_log
    from with_duration

)

select *
from final

{% else %}

select

    {% if target.type in ('sqlserver') %}
    top 0
    {% endif %}

    cast(null as {{ dbt.type_timestamp() }}) as started_at,
    cast(null as {{ dbt.type_timestamp() }}) as ended_at,
    cast(null as {{ dbt.type_int() }}) as duration_seconds,
    cast(null as {{ dbt.type_string() }}) as duration,
    cast(null as {{ dbt.type_string() }}) as destination_id,
    cast(null as {{ dbt.type_string() }}) as destination_name,
    cast(null as {{ dbt.type_string() }}) as transformation_name,
    cast(null as {{ dbt.type_string() }}) as transformation_id,
    cast(null as {{ dbt.type_string() }}) as transformation_type,
    cast(null as {{ dbt.type_int() }}) as successful_model_runs,
    cast(null as {{ dbt.type_int() }}) as failed_model_runs,
    cast(null as {{ dbt.type_string() }}) as transformation_status,
    cast(null as {{ dbt.type_string() }}) as event_subtype,
    cast(null as {{ dbt.type_string() }}) as full_run_log

    {% if target.type not in ('sqlserver') %}
    limit {{ '1' if target.type == 'redshift' else '0' }}
    {% endif %}

{% endif %}
