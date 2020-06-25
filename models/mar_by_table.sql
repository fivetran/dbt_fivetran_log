with ordered_mar as (
    select
        connector_id,
        schema_name,
        table_name,
        destination_id,
        measured_at,
        monthly_active_rows,
        row_number() over(partition by table_name, connector_id, destination_id order by measured_at desc) as n

    from {{ var('active_volume') }}

    where schema_name != 'fivetran_log' -- or whatever the variable is in dbt_project

),

latest_mar as (
  select 
    schema_name,
    table_name,
    connector_id,
    destination_id,
    date(measured_at) as last_measurement_date,
    DATE_TRUNC(date(measured_at), month ) as last_measurement_month,
    sum(monthly_active_rows) as monthly_active_rows
  
  from ordered_mar
  where n = 1
  group by 1,2,3,4,5,6

)

select * from latest_mar


