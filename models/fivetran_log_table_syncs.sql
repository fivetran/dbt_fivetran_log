with syncs as (

    select *
    from {{ ref('stg_fivetran_log_log') }}

    where message_event = 'sync_start' 
        or message_event = 'sync_end'
) 

select * from syncs