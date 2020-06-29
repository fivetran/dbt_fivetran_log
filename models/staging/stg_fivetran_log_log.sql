with log as (

    select *
    from {{ var('log') }}
),

fields as (

    select
        id as log_id, -- unclear what this is
        time_stamp as created_at,
        connector_id,
        case when transformation_id is not null and event is null then 'TRANSFORMATION'
        else event end as event_type, 
        -- event as event_type, -- eh different names for these? TODO
        message_data,
        case when transformation_id is not null and message_event is null then 'transformation'
        else message_event end as message_event,
        -- message_event,
        transformation_id

    from log
)

select * from fields 