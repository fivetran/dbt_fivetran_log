{{ config(
    materialized = 'incremental',
    unique_key = (
        'unique_schema_change_key' if (
            (target.type in ('postgres', 'redshift', 'snowflake', 'sqlserver'))
            or (target.type=='databricks' and not fivetran_log.is_databricks_all_purpose_cluster())
            )
        else None
    ),
    partition_by = (
        {'field': 'schema_change_day', 'data_type': 'date'} if target.type == 'bigquery'
        else ['schema_change_day'] if fivetran_log.is_databricks_all_purpose_cluster()
        else None
    ),
    cluster_by = (
        ['schema_change_day'] if target.type == 'snowflake'
        else None
    ),
    incremental_strategy = (
        'merge' if (target.type=='databricks' and not fivetran_log.is_databricks_all_purpose_cluster())
        else 'insert_overwrite' if target.type in ('bigquery', 'spark', 'databricks')
        else 'merge' if target.type == 'snowflake'
        else 'delete+insert' if fivetran_log.is_incremental_compatible()
        else None
    ),
    file_format = (
        'delta' if target.type=='databricks'
        else None
    )
) }}

with schema_changes as (

    select *
    from {{ ref('stg_fivetran_platform__log') }}

    where event_subtype in ('create_table', 'alter_table', 'create_schema', 'change_schema_config')

    {% if is_incremental() %}
    and cast(created_at as date) > {{ fivetran_log.fivetran_log_lookback(from_date='max(schema_change_day)', interval=7) }}
    {% endif %}
),

connection as (

    select *
    from {{ ref('fivetran_platform__connection_status') }}
),

add_connection_info as (

    select 
        schema_changes.*,
        connection.connection_name,
        connection.destination_id,
        connection.destination_name

    from schema_changes join connection 
        on schema_changes.connection_id = connection.connection_id
),

final as (

    select
        connection_id,
        connection_name,
        destination_id,
        destination_name,
        created_at,
        event_subtype,
        message_data,

        case 
        when event_subtype = 'alter_table' then {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['table']) }} 
        when event_subtype = 'create_table' then {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['name']) }}
        else null end as table_name,

        case 
        when event_subtype = 'create_schema' or event_subtype = 'create_table' then {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['schema']) }}
        else null end as schema_name,

        {{ dbt_utils.generate_surrogate_key(['connection_id', 'created_at', 'event_subtype', 'message_data']) }} as unique_schema_change_key,
        cast({{ dbt.date_trunc('day', 'created_at') }} as date) as schema_change_day

    from add_connection_info
)

select * from final
