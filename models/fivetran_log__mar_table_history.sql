with active_volume as (

    select 
        *, 
        {{ dbt_utils.date_trunc('month', 'measured_at') }} as measured_month

    from {{ ref('stg_fivetran_log__active_volume') }} 

    where schema_name != 'fivetran_log' -- it's free! 

),

connector as (

    select * 
    from {{ ref('stg_fivetran_log__connector') }}
),

destination as (

    select *
    from {{ ref('stg_fivetran_log__destination') }}
),

ordered_mar as (

    select
        connector_name,
        schema_name,
        table_name,
        destination_id,
        measured_at,
        measured_month,
        monthly_active_rows,

        -- each measurement is cumulative for the month, so we'll only look at the latest date for each month
        row_number() over(partition by table_name, connector_name, destination_id, measured_month order by measured_at desc) as n

    from active_volume

),

latest_mar as (
    select 
        connector_name,
        schema_name,
        table_name,
        destination_id,
        measured_month,
        date(measured_at) as last_measured_at,
        monthly_active_rows
    
    from ordered_mar
    where n = 1

),

mar_join as (

    select 
        latest_mar.*,
        connector.connector_type,
        connector.connector_id,
        destination.destination_name

    from latest_mar
    join connector 
        on latest_mar.connector_name = connector.connector_name
        and latest_mar.destination_id = connector.destination_id
    join destination on latest_mar.destination_id = destination.destination_id
)

select * from mar_join
order by measured_month desc, destination_id, connector_name
