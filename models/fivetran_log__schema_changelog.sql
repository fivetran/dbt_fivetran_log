with schema_changes as (

    select *
    from {{ ref('stg_fivetran_log__log') }}

    where event_subtype in ('create_table', 'alter_table', 'create_schema', 'change_schema_config')
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

    from schema_changes join connector using(connector_id)
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
        when event_subtype = 'alter_table' then {{ fivetran_utils.json_parse(string='message_data', string_path=['table']) }} 
        when event_subtype = 'create_table' then {{ fivetran_utils.json_parse(string='message_data', string_path=['name']) }} 
        else null end as table_name,

        case 
        when event_subtype = 'create_schema' or event_subtype = 'create_table' then {{ fivetran_utils.json_parse(string='message_data', string_path=['schema']) }} 
        else null end as schema_name
    
    from add_connector_info
)

select * from final
order by created_at desc, connector_id