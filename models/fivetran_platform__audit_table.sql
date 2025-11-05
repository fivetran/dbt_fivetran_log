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

sessionize as (

    select 
        connection_id,
        created_at,
        event_subtype,
        table_name,
        schema_name,
        operation_type,
        row_count,
        sum(case when event_subtype = 'sync_start' then 1 else 0 end) over (partition by connection_id order by created_at asc rows between unbounded preceding and current row) as sync_session_id

    from parsed
),

session_timestamps as (

    select 
        connection_id,
        created_at,
        event_subtype,
        table_name,
        sync_session_id,
        schema_name,
        operation_type,
        row_count,

        min(case when event_subtype = 'sync_start' then created_at else null end) over (partition by connection_id, sync_session_id order by created_at) as sync_start,

        -- purposely not including sync_session_id in partition 
        min(case when event_subtype = 'sync_end' then created_at else null end) over (partition by connection_id order by created_at asc rows between current row and unbounded following) as sync_end,
        min(case when event_subtype = 'sync_start' then created_at else null end) over (partition by connection_id order by created_at asc rows between current row and unbounded following) as next_sync_start,
        
        min(case when event_subtype = 'write_to_table_end' then created_at else null end) 
            over (partition by connection_id, table_name order by created_at ROWS between CURRENT ROW AND UNBOUNDED FOLLOWING) as next_write_to_table_end,

        max(case when event_subtype = 'write_to_table_end' then created_at else null end) 
            over (partition by connection_id, table_name order by created_at ROWS between UNBOUNDED PRECEDING AND CURRENT ROW) as prev_write_to_table_end,

        min(case when event_subtype = 'records_modified' then created_at else null end) over (partition by connection_id, table_name, sync_session_id order by created_at asc rows between current row and unbounded following) as next_records_modified,

        row_number() over (partition by connection_id, table_name, sync_session_id, event_subtype order by created_at) as event_group

    from sessionize
),

write_start_timestamps as (
    
    select 
        connection_id,
        created_at,
        event_subtype,
        table_name,
        sync_session_id,
        schema_name,
        operation_type,
        row_count,
        sync_start,
        sync_end,
        next_sync_start,
        coalesce(prev_write_to_table_end, next_write_to_table_end) as write_to_table_end,
        next_records_modified,
        
        max(case when event_subtype = 'write_to_table_start' then created_at else null end) over (partition by connection_id, table_name, sync_session_id, event_group order by created_at rows between unbounded preceding and current row) as write_to_table_start,
        max(case when event_subtype = 'write_to_table_start' then created_at else null end) over (partition by connection_id, table_name order by created_at ROWS between UNBOUNDED PRECEDING AND CURRENT ROW) as backup_write_to_table_start
    
    from session_timestamps
),

row_modifcation_counts as (

    select
        connection_id,
        table_name,
        schema_name,
        coalesce(write_to_table_start, backup_write_to_table_start) as write_to_table_start,
        min(write_to_table_end) as write_to_table_end,
        min(sync_start) as sync_start,
        min(next_sync_start) as next_sync_start,
        min(sync_end) as sync_end,

        sum(case when event_subtype = 'records_modified' and operation_type = 'REPLACED_OR_INSERTED' 
                and created_at >= sync_start and created_at < coalesce(sync_end, next_sync_start)
                then row_count else 0  end) as sum_rows_replaced_or_inserted,

        sum(case when event_subtype = 'records_modified' and operation_type = 'UPDATED' 
                and created_at >= sync_start and created_at < coalesce(sync_end, next_sync_start)
                then row_count else 0  end) as sum_rows_updated,

        sum(case when event_subtype = 'records_modified' and operation_type = 'DELETED' 
                and created_at >= sync_start and created_at < coalesce(sync_end, next_sync_start)
                then row_count else 0  end) as sum_rows_deleted

    from write_start_timestamps
    where event_subtype = 'records_modified'

    group by
        connection_id,
        table_name,
        schema_name,
        write_to_table_start
),

connection as (

    select *
    from {{ ref('fivetran_platform__connection_status') }}
),

add_connection_info as (

    select 
        row_modifcation_counts.connection_id,
        connection.connection_name,
        coalesce(row_modifcation_counts.schema_name, connection.connection_name) as schema_name,
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

    from row_modifcation_counts 
    left join connection
        on connection.connection_id = row_modifcation_counts.connection_id
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
