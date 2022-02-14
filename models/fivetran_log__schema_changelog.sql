{{ config(
    materialized='incremental',
    unique_key='unique_schema_change_key',
    partition_by={
        'field': 'created_at',
        'data_type': 'timestamp',
        'granularity': 'day'
    } if target.type == 'bigquery' else none,
    incremental_strategy = 'merge',
    file_format = 'delta'
) }}

with schema_changes as (

    select *
    from {{ ref('stg_fivetran_log__log') }}

    where event_subtype in ('create_table', 'alter_table', 'create_schema', 'change_schema_config')

    {% if is_incremental() %}

    -- Capture the latest timestamp in a call statement instead of a subquery for optimizing BQ costs on incremental runs
    {%- call statement('max_schema_change', fetch_result=True) -%}
        select max(created_at) from {{ this }}
    {%- endcall -%}

    -- load the result from the above query into a new variable
    {%- set query_result = load_result('max_schema_change') -%}

    -- the query_result is stored as a dataframe. Therefore, we want to now store it as a singular value.
    {%- set max_schema_change = query_result['data'][0][0] -%}

        -- compare the new batch of data to the latest sync already stored in this model
        and created_at >= '{{ max_schema_change }}'

    {% endif %}
),

connector as (

    select *
    from {{ ref('fivetran_log__connector_status') }}
),

add_connector_info as (

    select 
        schema_changes.*,
        connector.connector_name,
        connector.destination_id,
        connector.destination_name

    from schema_changes join 
        connector on schema_changes.connector_id = connector.connector_id
),

final as (

    select
        connector_id,
        connector_name,
        destination_id,
        destination_name,
        created_at,
        event_subtype,
        message_data,

        case 
        when event_subtype = 'alter_table' then {{ fivetran_utils.json_extract(string='message_data', string_path='table') }} 
        when event_subtype = 'create_table' then {{ fivetran_utils.json_extract(string='message_data', string_path='name') }} 
        else null end as table_name,

        case 
        when event_subtype = 'create_schema' or event_subtype = 'create_table' then {{ fivetran_utils.json_extract(string='message_data', string_path='schema') }} 
        else null end as schema_name,

        {{ dbt_utils.surrogate_key(['connector_id', 'destination_id', 'created_at']) }} as unique_schema_change_key

    
    from add_connector_info
)

select * from final