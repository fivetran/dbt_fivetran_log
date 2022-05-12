{{ config(
    materialized='incremental',
    unique_key='unique_table_sync_key',
    partition_by={
        'field': 'sync_start',
        'data_type': 'timestamp',
        'granularity': 'day'
    } if target.type == 'bigquery' else none,
    incremental_strategy = 'merge',
    file_format = 'delta'
) }}

with sync_log as (
    
    select 
        *,
        {{ fivetran_utils.json_parse(string='message_data', string_path=['table']) }} as table_name
    from {{ ref('stg_fivetran_log__log') }}
    where event_subtype in ('sync_start', 'sync_end', 'write_to_table_start', 'write_to_table_end', 'records_modified')

    {% if is_incremental() %}

    -- Capture the latest timestamp in a call statement instead of a subquery for optimizing BQ costs on incremental runs
    {%- call statement('max_sync_start', fetch_result=True) -%}
        select date(max(sync_start)) from {{ this }}
    {%- endcall -%}

    -- load the result from the above query into a new variable
    {%- set query_result = load_result('max_sync_start') -%}

    -- the query_result is stored as a dataframe. Therefore, we want to now store it as a singular value.
    {%- set max_sync_start = query_result['data'][0][0] -%}

    -- compare the new batch of data to the latest sync already stored in this model
    and date(created_at) >= '{{ max_sync_start }}'

    {% endif %}
),


connector as (

    select *
    from {{ ref('fivetran_log__connector_status') }}
),

add_connector_info as (

    select 
        sync_log.*,
        connector.connector_name,
        connector.destination_id,
        connector.destination_name
    from sync_log 
    left join connector
        on connector.connector_id = sync_log.connector_id
),

sync_timestamps as (

    select
        connector_id,
        connector_name,
        table_name,
        event_subtype,
        destination_id,
        destination_name,
        created_at as write_to_table_start,
        min(case when event_subtype = 'write_to_table_end' then created_at else null end) 
            over (partition by connector_id, table_name order by created_at ROWS between CURRENT ROW AND UNBOUNDED FOLLOWING) as write_to_table_end,

        max(case when event_subtype = 'sync_start' then created_at else null end) 
            over (partition by connector_id order by created_at ROWS between UNBOUNDED PRECEDING and CURRENT ROW) as sync_start,

        min(case when event_subtype = 'sync_end' then created_at else null end) 
            over (partition by connector_id order by created_at ROWS between CURRENT ROW AND UNBOUNDED FOLLOWING) as sync_end, -- coalesce with next_sync_start

        min(case when event_subtype = 'sync_start' then created_at else null end) 
            over (partition by connector_id order by created_at ROWS between CURRENT ROW AND UNBOUNDED FOLLOWING) as next_sync_start
    from add_connector_info
),

-- this will be the base for every record in the final CTE
limit_to_table_starts as (

    select *
    from sync_timestamps 
    where event_subtype = 'write_to_table_start'
),

records_modified_log as (

    select 
        connector_id,
        created_at,
        {{ fivetran_utils.json_parse(string='message_data', string_path=['table']) }} as table_name,
        {{ fivetran_utils.json_parse(string='message_data', string_path=['schema']) }} as schema_name,
        {{ fivetran_utils.json_parse(string='message_data', string_path=['operationType']) }} as operation_type,
        cast ({{ fivetran_utils.json_parse(string='message_data', string_path=['count']) }} as {{ dbt_utils.type_int() }}) as row_count
    from sync_log 
    where event_subtype = 'records_modified'

),

sum_records_modified as (

    select
        limit_to_table_starts.connector_id,
        limit_to_table_starts.connector_name,
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
        limit_to_table_starts.connector_id = records_modified_log.connector_id
        and limit_to_table_starts.table_name = records_modified_log.table_name

        -- confine it to one sync
        and records_modified_log.created_at > limit_to_table_starts.sync_start 
        and records_modified_log.created_at < coalesce(limit_to_table_starts.sync_end, limit_to_table_starts.next_sync_start) 

    {{ dbt_utils.group_by(n=9) }}
),

surrogate_key as (

    select 
        *,
        {{ dbt_utils.surrogate_key(['connector_id', 'destination_id', 'table_name', 'write_to_table_start']) }} as unique_table_sync_key
    from sum_records_modified
)

select *
from surrogate_key