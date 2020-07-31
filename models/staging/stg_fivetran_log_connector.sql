with connector as (

    {{ union_source_tables('connector') }}

),
-- TODO: de-dupe connectors (multiple connector_id's) -- maybe add flag has_been_re_added
fields as (

    select 
        connector_id,
        connecting_user_id,
        connector_name,
        connector_type,  -- use coalesce(connector_type, service) if the table has a service column (deprecated)
        destination_id,
        paused as is_paused,
        signed_up as signed_up_at,
        destination_database

    from connector
)

select * from fields