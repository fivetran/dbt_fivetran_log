with active_volume as (

    select * from {{ var('active_volume') }}
),

fields as (

    select
        id as active_volume_id,
        connector_id as connector_name, -- Note: this misnomer will be changed by Fivetran soon
        destination_id,
        cast(measured_at as {{ dbt_utils.type_timestamp() }}) as measured_at,
        monthly_active_rows,
        schema_name,
        table_name
    from active_volume
)

select * 
from fields
