with log as (

    select *
    from {{ ref('stg_fivetran_platform__log') }}
),

-- sync_id is unique across connections, so this is one row per sync
sync as (

    select
        sync_id,
        connection_id,
        max(created_at) as sync_completed_at,
        sum(case when event_subtype = 'sync_end' then 1 else 0 end) as sync_end_events,

        max(case when event_subtype = 'sync_end'
            then cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['status']) }} as {{ dbt.type_string() }})
            else null end) as sync_status

    from log
    where sync_id is not null
    group by sync_id, connection_id
),

-- a sync with no sync_end event never finished
completed_syncs as (

    select
        sync_id,
        connection_id,
        sync_completed_at,
        sync_status

    from sync
    where sync_end_events > 0
),

-- a sync occasionally logs more than one sync_stats event; keep the latest
sync_stats_ranked as (

    select
        log_id,
        sync_id,
        message_data,
        row_number() over (
            partition by sync_id
            order by created_at desc
        ) as nth_sync_stats_record

    from log
    where event_subtype = 'sync_stats'
        and sync_id is not null
),

sync_stats as (

    select
        log_id,
        sync_id,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['extract_time_s']) }} as {{ dbt.type_float() }}) as extract_time_s,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['extract_volume_mb']) }} as {{ dbt.type_float() }}) as extract_volume_mb,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['process_time_s']) }} as {{ dbt.type_float() }}) as process_time_s,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['process_volume_mb']) }} as {{ dbt.type_float() }}) as process_volume_mb,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['load_time_s']) }} as {{ dbt.type_float() }}) as load_time_s,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['load_volume_mb']) }} as {{ dbt.type_float() }}) as load_volume_mb,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['total_time_s']) }} as {{ dbt.type_float() }}) as total_time_s

    from sync_stats_ranked
    where nth_sync_stats_record = 1
),

extract_summary as (

    select
        sync_id,
        sum(cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['total_rows']) }} as {{ dbt.type_bigint() }})) as total_extracted_rows

    from log
    where event_subtype = 'extract_summary'
        and sync_id is not null
    group by sync_id
),

-- total records modified per sync, to pair row counts with each sync's duration
records_modified as (

    select
        sync_id,
        sum(cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['count']) }} as {{ dbt.type_bigint() }})) as row_count

    from log
    where event_subtype = 'records_modified'
        and sync_id is not null
    group by sync_id
),

connection_ranked as (

    select
        *,
        row_number() over (
            partition by connection_id
            order by is_deleted asc, set_up_at desc
        ) as nth_connection_record
    from {{ ref('stg_fivetran_platform__connection') }}
),

-- dedupe to one row per connection_id, preferring the active, most-recent record
connection as (

    select
        connection_id,
        connection_name,
        connector_type,
        destination_id
    from connection_ranked
    where nth_connection_record = 1
),

destination as (

    select *
    from {{ ref('stg_fivetran_platform__destination') }}
),

joined as (

    select
        {{ dbt_utils.generate_surrogate_key(['completed_syncs.connection_id', 'completed_syncs.sync_id', 'completed_syncs.sync_completed_at']) }} as unique_sync_key,
        sync_stats.log_id,
        completed_syncs.sync_id,
        completed_syncs.connection_id,
        connection.connection_name,
        connection.connector_type,
        connection.destination_id,
        destination.destination_name,
        completed_syncs.sync_completed_at,
        cast({{ dbt.date_trunc('day', 'completed_syncs.sync_completed_at') }} as date) as date_day,

        {% if target.type != 'sqlserver' -%}
        {{ fivetran_log.fivetran_day_name('completed_syncs.sync_completed_at', short=False) }} as day_of_week,
        {% else -%}
        format(cast(completed_syncs.sync_completed_at as date), 'dddd') as day_of_week,
        {% endif -%}

        completed_syncs.sync_status,
        sync_stats.extract_time_s,
        sync_stats.extract_volume_mb,
        sync_stats.process_time_s,
        sync_stats.process_volume_mb,
        sync_stats.load_time_s,
        sync_stats.load_volume_mb,
        sync_stats.total_time_s,
        extract_summary.total_extracted_rows,
        records_modified.row_count as total_loaded_rows

    from completed_syncs
    left join sync_stats
        on completed_syncs.sync_id = sync_stats.sync_id
    left join extract_summary
        on completed_syncs.sync_id = extract_summary.sync_id
    left join records_modified
        on completed_syncs.sync_id = records_modified.sync_id
    left join connection
        on completed_syncs.connection_id = connection.connection_id
    left join destination
        on connection.destination_id = destination.destination_id
)

select *
from joined
