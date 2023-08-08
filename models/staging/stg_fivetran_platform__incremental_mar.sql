with base as (

    select * 
    from {{ var('incremental_mar') }}
),

fields as (

    select
        connector_id as connector_name,
        destination_id,
        free_type,
        cast(measured_date as {{ dbt.type_timestamp() }}) as measured_date,
        schema_name,
        sync_type,
        table_name,
        updated_at,
        _fivetran_synced,
        incremental_rows
    from base
)

select * 
from fields