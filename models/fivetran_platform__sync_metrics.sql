with log as (

    select *
    from {{ ref('stg_fivetran_platform__log') }}
),

-- one row per completed sync, with the extract/process/load timing and volume stats
sync_stats as (

    select
        log_id,
        sync_id,
        connection_id,
        created_at as sync_completed_at,
        cast({{ dbt.date_trunc('day', 'created_at') }} as date) as date_day,

        {% if target.type != 'sqlserver' -%}
        {{ fivetran_log.fivetran_day_name('created_at', short=False) }} as day_of_week,
        {% else -%}
        format(cast(created_at as date), 'dddd') as day_of_week,
        {% endif -%}

        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['extract_time_s']) }} as {{ dbt.type_float() }}) as extract_time_s,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['extract_volume_mb']) }} as {{ dbt.type_float() }}) as extract_volume_mb,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['process_time_s']) }} as {{ dbt.type_float() }}) as process_time_s,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['process_volume_mb']) }} as {{ dbt.type_float() }}) as process_volume_mb,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['load_time_s']) }} as {{ dbt.type_float() }}) as load_time_s,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['load_volume_mb']) }} as {{ dbt.type_float() }}) as load_volume_mb,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['total_time_s']) }} as {{ dbt.type_float() }}) as total_time_s

    from log
    where event_subtype = 'sync_stats'
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
        {{ dbt_utils.generate_surrogate_key(['sync_stats.connection_id', 'sync_stats.sync_id', 'sync_stats.sync_completed_at']) }} as unique_sync_key,
        sync_stats.log_id,
        sync_stats.sync_id,
        sync_stats.connection_id,
        connection.connection_name,
        connection.connector_type,
        connection.destination_id,
        destination.destination_name,
        sync_stats.sync_completed_at,
        sync_stats.date_day,
        sync_stats.day_of_week,
        sync_stats.extract_time_s,
        sync_stats.extract_volume_mb,
        sync_stats.process_time_s,
        sync_stats.process_volume_mb,
        sync_stats.load_time_s,
        sync_stats.load_volume_mb,
        sync_stats.total_time_s,
        records_modified.row_count as rows_modified_count

    from sync_stats
    left join records_modified
        on sync_stats.sync_id = records_modified.sync_id
    left join connection
        on sync_stats.connection_id = connection.connection_id
    left join destination
        on connection.destination_id = destination.destination_id
)

select *
from joined
