with log as (

    select *
    from {{ ref('stg_fivetran_log_log') }}

    where event_type != 'TRANSFORMATION'

),

connecor as (

    select *
    from {{ var('connector') }}

),


order_logs as (

    select
        connecor_id,
        event_type,
        event_subtype,
        message_data,
        row_number() over(partition by connector_id order by created_at desc) as nth_last_event,
        row_number() over(partition by connector_id, event_type order by created_at desc) as nth_last_type_of_event,
        row_number() over(partition by connector_id, event_subtype order by created_at desc) as nth_last_subtype_of_event

    from log
    -- last error -- last error if broken
    -- last sync start -- last sync start before the last sync_end
    --  last event - what is it? error or sync_start or sync_end or warning?
),

last_event as (

    select  
        connecor_id,
        case when nth_last_event = 1 and event_subtype = 'sync_start' then 'in progress'
        when nth_last_event = 1 and event_subtype = 'sync_end' then 'up-to-date'
        when nth_last_event = 1 and event_type = 'ERROR' then 'broken'
        when nth_last_event = 1 and event_type = 'WARNING' then 'warning'
        else null end as status, -- will overwrite with is_paused if it's paused

) 

select * from connector