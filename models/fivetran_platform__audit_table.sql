{{ config(
    materialized = (
        'incremental' if fivetran_log.is_incremental_compatible() 
        else 'table'
    ),
    unique_key = (
        'unique_table_sync_key' if (
            (target.type in ('postgres', 'redshift', 'snowflake', 'sqlserver'))
            or (target.type=='databricks' and not fivetran_log.is_databricks_all_purpose_cluster())
            )
        else None
    ),
    partition_by = (
        {'field': 'write_to_table_start_day', 'data_type': 'date'} if target.type == 'bigquery'
        else ['write_to_table_start_day'] if fivetran_log.is_databricks_all_purpose_cluster()
        else None
    ),
    cluster_by = (
        ['write_to_table_start_day'] if target.type == 'snowflake'
        else None
    ),
    incremental_strategy = (
        'merge' if (target.type=='databricks' and not fivetran_log.is_databricks_all_purpose_cluster())
        else 'insert_overwrite' if target.type in ('bigquery', 'spark', 'databricks')
        else 'delete+insert' if fivetran_log.is_incremental_compatible()
        else None
    ),
    file_format = (
        'delta' if target.type=='databricks'
        else None
    )
) }}

with base as (
    
    select
        connection_id,
        created_at,
        event_subtype, 
        replace(message_data, 'operationType', 'operation_type') as message_data
    from {{ ref('stg_fivetran_platform__log') }}
    where event_subtype in ('sync_start', 'sync_end', 'write_to_table_start', 'write_to_table_end', 'records_modified')

    {% if is_incremental() %}
    and cast(created_at as date) > {{ fivetran_log.fivetran_log_lookback(from_date='max(write_to_table_start_day)', interval=7) }}
    {% endif %}
),

parsed as (
    select 
        connection_id,
        created_at,
        event_subtype,
        message_data,
        {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['table']) }} as table_name,

        case 
            when event_subtype = 'records_modified' then {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['schema']) }} 
            else cast(null as {{ dbt.type_string() }})
        end as schema_name,

        case 
            when event_subtype = 'records_modified' then {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['operation_type']) }} 
            else cast(null as {{ dbt.type_string() }})
        end as operation_type,

        cast(case 
            when event_subtype = 'records_modified' then {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['count']) }} 
            else null
        end as {{ dbt.type_bigint() }}) as row_count

    from base
),

sync_timestamps as (

    select
        connection_id,
        table_name,
        event_subtype,
        created_at,
        schema_name,
        operation_type,
        row_count,

        case 
            when event_subtype in ('write_to_table_start', 'records_modified') then 
            min(case when event_subtype = 'write_to_table_end' then created_at else null end) 
                over (partition by connection_id, table_name order by created_at ROWS between CURRENT ROW AND UNBOUNDED FOLLOWING) 
        else null end as write_to_table_end,

        case 
            when event_subtype in ('write_to_table_start', 'records_modified') then 
        max(case when event_subtype = 'sync_start' then created_at else null end) 
            over (partition by connection_id order by created_at ROWS between UNBOUNDED PRECEDING and CURRENT ROW) 
        else null end as sync_start,

        case 
            when event_subtype in ('write_to_table_start', 'records_modified') then 
        min(case when event_subtype = 'sync_start' then created_at else null end) 
            over (partition by connection_id order by created_at ROWS between CURRENT ROW AND UNBOUNDED FOLLOWING)
        else null end as next_sync_start,

        case 
            when event_subtype in ('write_to_table_start', 'records_modified') then 
        min(case when event_subtype = 'sync_end' then created_at else null end) 
            over (partition by connection_id order by created_at ROWS between CURRENT ROW AND UNBOUNDED FOLLOWING) 
        else null end as sync_end -- coalesce with next_sync_start

    from parsed

),

row_modifcation_counts as (

    select
        *,
        case when event_subtype = 'write_to_table_start' then
        sum(case when event_subtype = 'records_modified' and operation_type = 'REPLACED_OR_INSERTED' 
                and created_at >= sync_start and created_at < coalesce(sync_end, next_sync_start)
                then row_count else 0  end)
        over (partition by connection_id, table_name, sync_start) else null end as sum_rows_replaced_or_inserted,

        case when event_subtype = 'write_to_table_start' then
        sum(case when event_subtype = 'records_modified' and operation_type = 'UPDATED' 
                and created_at >= sync_start and created_at < coalesce(sync_end, next_sync_start)
                then row_count else 0  end)
        over (partition by connection_id, table_name, sync_start) else null end as sum_rows_updated,

        case when event_subtype = 'write_to_table_start' then
        sum(case when event_subtype = 'records_modified' and operation_type = 'DELETED' 
                and created_at >= sync_start and created_at < coalesce(sync_end, next_sync_start)
                then row_count else 0  end)
        over (partition by connection_id, table_name, sync_start) else null end as sum_rows_deleted

    from sync_timestamps
    where event_subtype in ('write_to_table_start', 'records_modified')
),

limit_to_table_starts as (

    select 
        connection_id,
        schema_name,
        table_name,
        created_at as write_to_table_start,
        write_to_table_end,
        sync_start,
        case when sync_end > next_sync_start then null else sync_end end as sync_end,
        sum_rows_replaced_or_inserted,
        sum_rows_updated,
        sum_rows_deleted

    from row_modifcation_counts 
    where event_subtype = 'write_to_table_start'
),

connection as (

    select *
    from {{ ref('fivetran_platform__connection_status') }}
),

add_connection_info as (

    select 
        limit_to_table_starts.connection_id,
        connection.connection_name,
        coalesce(limit_to_table_starts.schema_name, connection.connection_name) as schema_name,
        table_name,
        connection.destination_id,
        connection.destination_name,
        write_to_table_start,
        write_to_table_end,
        sync_start,
        sync_end,
        sum_rows_replaced_or_inserted,
        sum_rows_updated,
        sum_rows_deleted

    from limit_to_table_starts 
    left join connection
        on connection.connection_id = limit_to_table_starts.connection_id
),

final as (

    select 
        *,
        {{ dbt_utils.generate_surrogate_key(['schema_name','connection_id', 'destination_id', 'table_name', 'write_to_table_start']) }} as unique_table_sync_key, -- for incremental materialization 
        cast({{ dbt.date_trunc('day', 'write_to_table_start') }} as date) as write_to_table_start_day -- for partitioning
    from add_connection_info
)

select *
from final
