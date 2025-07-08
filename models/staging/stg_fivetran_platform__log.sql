{% set source_columns_in_relation = adapter.get_columns_in_relation(ref('stg_fivetran_platform__log_tmp')) %}

with base as (

    select * 
    from {{ ref('stg_fivetran_platform__log_tmp') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=source_columns_in_relation,
                staging_columns=get_log_columns()
            )
        }}
    from base
),

field_conversion as (
    select
        *,
        {{ fivetran_log.json_to_string("message_data", source_columns_in_relation) }} as message_data_string
    from fields
),

final as (

    select
        id as log_id,
        sync_id,
        cast(time_stamp as {{ dbt.type_timestamp() }}) as created_at,
        {{ fivetran_log.coalesce_cast(['connection_id', 'connector_id'], dbt.type_string()) }} as connection_id,
        case when transformation_id is not null and event is null then 'TRANSFORMATION'
        else event end as event_type,
        message_data_string as message_data,
        case
        when transformation_id is not null and message_data_string like '%has succeeded%' then 'transformation run success'
        when transformation_id is not null and message_data_string like '%has failed%' then 'transformation run failed'
        else message_event end as event_subtype,
        transformation_id
    from field_conversion
)

select * 
from final
