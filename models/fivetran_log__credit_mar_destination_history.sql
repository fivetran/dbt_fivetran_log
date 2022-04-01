with table_mar as (
    
    select *
    from {{ ref('fivetran_log__mar_table_history') }}
),

consumption_cost as (
    select *
    from {{ ref('stg_fivetran_log__credits_used') }}

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

join_credits_mar as (

    select 
        destination_mar.measured_month,
        destination_mar.destination_id,
        destination_mar.destination_name,
        usage.consumption,
        destination_mar.monthly_active_rows,
        round( nullif(usage.consumption,0) * 1000000.0 / nullif(destination_mar.monthly_active_rows,0), 2) as credits_per_million_mar,
        round( nullif(destination_mar.monthly_active_rows,0) * 1.0 / nullif(usage.consumption,0), 0) as mar_per_credit

    from 
    destination_mar left join usage 
        on destination_mar.measured_month = cast(usage.measured_month as timestamp)
        and destination_mar.destination_id = usage.destination_id

)

select * from join_credits_mar
order by measured_month desc