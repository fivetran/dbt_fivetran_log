with table_mar as (
    
    select *
    from {{ ref('fivetran_log__mar_table_history') }}
),

consumption_cost as (
    select *
    from {{ ref('stg_fivetran_log__usage') }}

),

destination_mar as (

    select 
        measured_month,
        destination_id,
        destination_name,
        sum(monthly_active_rows) as monthly_active_rows
    
    from table_mar
    group by 1,2,3
),

usage as (

    select 
        destination_id,
        consumption_amount as consumption,
        cast(concat(measured_month, '-01') as date) as measured_month -- match date format to join with MAR table

    from consumption_cost
),

join_usage_mar as (

    select 
        destination_mar.measured_month,
        destination_mar.destination_id,
        destination_mar.destination_name,
        usage.consumption,
        destination_mar.monthly_active_rows,
        round( cast(nullif(usage.consumption,0) * 1000000.0 as {{ dbt_utils.type_numeric() }}) / cast(nullif(destination_mar.monthly_active_rows,0) as {{ dbt_utils.type_numeric() }}), 2) as usage_per_million_mar,
        round( cast(nullif(destination_mar.monthly_active_rows,0) * 1.0 as {{ dbt_utils.type_numeric() }}) / cast(nullif(usage.consumption,0) as {{ dbt_utils.type_numeric() }}), 0) as mar_per_usage

    from 
    destination_mar left join usage 
        on destination_mar.measured_month = cast(usage.measured_month as timestamp)
        and destination_mar.destination_id = usage.destination_id

)

select * from join_usage_mar
order by measured_month desc
