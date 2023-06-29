with base as (

    select * 
    from {{ ref('stg_fivetran_platform__log_tmp') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_fivetran_platform__log_tmp')),
                staging_columns=get_log_columns()
            )
        }}
    from base
),

final as (

    select
        id as log_id, 
        sync_id,
        cast(time_stamp as {{ dbt.type_timestamp() }}) as created_at,
        connector_id, -- Note: the connector_id column used to erroneously equal the connector_name, NOT its id.
        case when transformation_id is not null and event is null then 'TRANSFORMATION'
        else event end as event_type, 
        message_data,
        case 
        when transformation_id is not null and message_data like '%has succeeded%' then 'transformation run success'
        when transformation_id is not null and message_data like '%has failed%' then 'transformation run failed'
        else message_event end as event_subtype,
        transformation_id
    from fields
)

select * 
from final 