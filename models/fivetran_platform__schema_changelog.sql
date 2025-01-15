with schema_changes as (

    select *
    from {{ ref('stg_fivetran_platform__log') }}

    where event_subtype in ('create_table', 'alter_table', 'create_schema', 'change_schema_config')
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
        else null end as schema_name
    
    from add_connection_info
)

select * from final