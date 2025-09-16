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

sync_log as (
    select 
        *,
        {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['table']) }} as table_name,
        cast(null as {{ dbt.type_string() }}) as schema_name,
        cast(null as {{ dbt.type_string() }}) as operation_type,
        cast(null as {{ dbt.type_bigint() }}) as row_count
    from base
    where event_subtype in ('sync_start', 'sync_end', 'write_to_table_start', 'write_to_table_end')

    union all

    select 
        *,
        {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['table']) }} as table_name,
        {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['schema']) }} as schema_name,
        {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['operation_type']) }} as operation_type,
        cast ({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['count']) }} as {{ dbt.type_bigint() }}) as row_count
    from base
    where event_subtype = 'records_modified'
),

connection as (

    select *
    from {{ ref('fivetran_platform__connection_status') }}
),

add_connection_info as (

    select 
        sync_log.*,
        connection.connection_name,
        connection.destination_id,
        connection.destination_name
    from sync_log 
    left join connection
        on connection.connection_id = sync_log.connection_id
),

sync_timestamps as (

    select
        connection_id,
        connection_name,
        table_name,
        event_subtype,
        destination_id,
        destination_name,
        created_at as write_to_table_start,
        min(case when event_subtype = 'write_to_table_end' then created_at else null end) 
            over (partition by connection_id, table_name order by created_at ROWS between CURRENT ROW AND UNBOUNDED FOLLOWING) as write_to_table_end,

        max(case when event_subtype = 'sync_start' then created_at else null end) 
            over (partition by connection_id order by created_at ROWS between UNBOUNDED PRECEDING and CURRENT ROW) as sync_start,

        min(case when event_subtype = 'sync_end' then created_at else null end) 
            over (partition by connection_id order by created_at ROWS between CURRENT ROW AND UNBOUNDED FOLLOWING) as sync_end, -- coalesce with next_sync_start

        min(case when event_subtype = 'sync_start' then created_at else null end) 
            over (partition by connection_id order by created_at ROWS between CURRENT ROW AND UNBOUNDED FOLLOWING) as next_sync_start
    from add_connection_info
),

-- this will be the base for every record in the final CTE
limit_to_table_starts as (

    select *
    from sync_timestamps 
    where event_subtype = 'write_to_table_start'
),

records_modified_log as (

    select 
        connection_id,
        created_at,
        table_name,
        schema_name,
        operation_type,
        row_count
    from sync_log 
    where event_subtype = 'records_modified'
),

sum_records_modified as (

    select
        limit_to_table_starts.connection_id,
        limit_to_table_starts.connection_name,
        coalesce(records_modified_log.schema_name, limit_to_table_starts.connection_name) as schema_name,
        limit_to_table_starts.table_name,
        limit_to_table_starts.destination_id,
        limit_to_table_starts.destination_name,
        limit_to_table_starts.write_to_table_start,
        limit_to_table_starts.write_to_table_end,
        limit_to_table_starts.sync_start,
        case when limit_to_table_starts.sync_end > limit_to_table_starts.next_sync_start then null else limit_to_table_starts.sync_end end as sync_end,
        sum(case when records_modified_log.operation_type = 'REPLACED_OR_INSERTED' then records_modified_log.row_count else 0 end) as sum_rows_replaced_or_inserted,
        sum(case when records_modified_log.operation_type = 'UPDATED' then records_modified_log.row_count else 0 end) as sum_rows_updated,
        sum(case when records_modified_log.operation_type = 'DELETED' then records_modified_log.row_count else 0 end) as sum_rows_deleted
    from limit_to_table_starts
    left join records_modified_log on 
        limit_to_table_starts.connection_id = records_modified_log.connection_id
        and limit_to_table_starts.table_name = records_modified_log.table_name

        -- confine it to one sync
        and records_modified_log.created_at > limit_to_table_starts.sync_start 
        and records_modified_log.created_at < coalesce(limit_to_table_starts.sync_end, limit_to_table_starts.next_sync_start) 

    -- explicit group by needed for SQL Server
    group by 
        limit_to_table_starts.connection_id,
        limit_to_table_starts.connection_name,
        coalesce(records_modified_log.schema_name, limit_to_table_starts.connection_name),
        limit_to_table_starts.table_name,
        limit_to_table_starts.destination_id,
        limit_to_table_starts.destination_name,
        limit_to_table_starts.write_to_table_start,
        limit_to_table_starts.write_to_table_end,
        limit_to_table_starts.sync_start,
        case when limit_to_table_starts.sync_end > limit_to_table_starts.next_sync_start then null else limit_to_table_starts.sync_end end
),

final as (

    select 
        *,
        {{ dbt_utils.generate_surrogate_key(['schema_name','connection_id', 'destination_id', 'table_name', 'write_to_table_start']) }} as unique_table_sync_key, -- for incremental materialization 
        cast({{ dbt.date_trunc('day', 'write_to_table_start') }} as date) as write_to_table_start_day -- for partitioning
    from sum_records_modified
)

select *
from final