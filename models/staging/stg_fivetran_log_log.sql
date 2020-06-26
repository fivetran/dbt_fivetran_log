with log as (

    select *
    from {{ var('log') }}
),

fields as (

    select
        id as log_id,
        time_stamp,
        connector_id,
        event as event_type, -- eh different names for these?
        message_data,
        message_event,
        transformation_id

    from log
)

select * from fields 