with base as (

    select * 
    from {{ ref('stg_fivetran_platform__incremental_mar_tmp') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_fivetran_platform__incremental_mar_tmp')),
                staging_columns=get_incremental_mar_columns()
            )
        }}
    from base
),

final as (

    select
        coalesce(connector_name, connector_id) as connector_name,
        destination_id,
        free_type,
        cast(measured_date as {{ dbt.type_timestamp() }}) as measured_date,
        schema_name,
        sync_type,
        table_name,
        updated_at,
        _fivetran_synced,
        incremental_rows
    from fields
)

select * 
from fields