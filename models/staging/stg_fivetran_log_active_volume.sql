with active_volume as (
    
    {{ union_source_tables('active_volume') }}

),

fields as (

    select
        id as active_volume_id,
        connector_id as connector_name, -- Note: this misnomer will be changed by Fivetran soon.
        destination_id,
        measured_at,
        monthly_active_rows,
        schema_name,
        table_name,
        destination_database
    
    from active_volume
)

select * from fields