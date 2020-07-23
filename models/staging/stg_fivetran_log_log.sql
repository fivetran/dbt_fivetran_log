with log as (

    {% for source_destination in var('source_destinations')  %}
    select 
        *,
        '{{ source_destination }}' as source_destination
    from {{ source( source_destination, 'log') }} 
    {% if not loop.last -%} union all {%- endif %}
    {% endfor %}

),

fields as (

    select
        id as log_id, -- unclear what this is
        time_stamp as created_at,
        connector_id,
        case when transformation_id is not null and event is null then 'TRANSFORMATION'
        else event end as event_type, 
        message_data,
        case 
        -- TODO: are there are other forms of transformation events? i've seen "sending batch to [fivetran emails]..."
        when transformation_id is not null and message_data like '%has succeeded%' then 'transformation run success'
        when transformation_id is not null and message_data like '%has failed%' then 'transformation run failed'
        else message_event end as event_subtype,
        transformation_id,
        source_destination

    from log
)

select * from fields 