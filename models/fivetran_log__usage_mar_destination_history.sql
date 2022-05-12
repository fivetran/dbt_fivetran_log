with table_mar as (
    
    select *
    from {{ ref('fivetran_log__mar_table_history') }}
),

credits_used as (

    select *
    from {{ ref('stg_fivetran_log__credits_used') }}
),

useage_cost as (

    select *
    from {{ ref('stg_fivetran_log__usage_cost') }}
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
        coalesce(credits_used.destination_id, useage_cost.destination_id) as destination_id,
        credits_used.credits_spent,
        useage_cost.dollars_spent,
        cast(concat(coalesce(credits_used.measured_month,useage_cost.measured_month), '-01') as date) as measured_month -- match date format to join with MAR table
    from credits_used
    full outer join useage_cost
        on useage_cost.measured_month = credits_used.measured_month
),

join_usage_mar as (

    select 
        destination_mar.measured_month,
        destination_mar.destination_id,
        destination_mar.destination_name,
        usage.credits_spent,
        usage.dollars_spent,
        destination_mar.monthly_active_rows,

        -- credit and usage mar calculations
        round( cast(nullif(usage.credits_spent,0) * 1000000.0 as {{ dbt_utils.type_numeric() }}) / cast(nullif(destination_mar.monthly_active_rows,0) as {{ dbt_utils.type_numeric() }}), 2) as credits_spent_per_million_mar,
        round( cast(nullif(destination_mar.monthly_active_rows,0) * 1.0 as {{ dbt_utils.type_numeric() }}) / cast(nullif(usage.credits_spent,0) as {{ dbt_utils.type_numeric() }}), 0) as mar_per_credit_spent,
        round( cast(nullif(usage.dollars_spent,0) * 1000000.0 as {{ dbt_utils.type_numeric() }}) / cast(nullif(destination_mar.monthly_active_rows,0) as {{ dbt_utils.type_numeric() }}), 2) as amount_spent_per_million_mar,
        round( cast(nullif(destination_mar.monthly_active_rows,0) * 1.0 as {{ dbt_utils.type_numeric() }}) / cast(nullif(usage.dollars_spent,0) as {{ dbt_utils.type_numeric() }}), 0) as mar_per_amount_spent
    from destination_mar 
    left join usage 
        on destination_mar.measured_month = cast(usage.measured_month as timestamp)
        and destination_mar.destination_id = usage.destination_id
)

select * 
from join_usage_mar
order by measured_month desc
