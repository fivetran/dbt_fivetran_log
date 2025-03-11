with table_mar as (
    
    select *
    from {{ ref('fivetran_platform__mar_table_history') }}
),

credits_used as (

    select *
    from {{ ref('stg_fivetran_platform__credits_used') }}
),

usage_cost as (

    select *
    from {{ ref('stg_fivetran_platform__usage_cost') }}
),

transformation_runs as (

    select
        destination_id,
        measured_month,
        sum(case when lower(free_type) = 'paid' then model_runs else 0 end) as paid_model_runs,
        sum(case when lower(free_type) != 'paid' then model_runs else 0 end) as free_model_runs,
        sum(coalesce(model_runs, 0)) as total_model_runs
    from {{ ref('stg_fivetran_platform__transformation_runs') }}
    group by destination_id, measured_month
),

destination_mar as (

    select 
        cast(measured_month as date) as measured_month,
        destination_id,
        destination_name,
        sum(free_monthly_active_rows) as free_monthly_active_rows,
        sum(paid_monthly_active_rows) as paid_monthly_active_rows,
        sum(total_monthly_active_rows) as total_monthly_active_rows
    from table_mar
    group by measured_month, destination_id, destination_name
),

usage as (

    select 
        coalesce(credits_used.destination_id, usage_cost.destination_id) as destination_id,
        credits_used.credits_spent,
        usage_cost.dollars_spent,
        cast(concat(coalesce(credits_used.measured_month,usage_cost.measured_month), '-01') as date) as measured_month -- match date format to join with MAR table
    from credits_used
    full outer join usage_cost
        on usage_cost.measured_month = credits_used.measured_month
        and usage_cost.destination_id = credits_used.destination_id
),

join_usage_mar as (

    select 
        destination_mar.measured_month,
        destination_mar.destination_id,
        destination_mar.destination_name,
        usage.credits_spent,
        usage.dollars_spent,
        destination_mar.free_monthly_active_rows,
        destination_mar.paid_monthly_active_rows,
        destination_mar.total_monthly_active_rows,
        transformation_runs.paid_model_runs,
        transformation_runs.free_model_runs,
        transformation_runs.total_model_runs,

        -- credit and usage mar calculations
        round( cast(nullif(usage.credits_spent,0) * 1000000.0 as {{ dbt.type_numeric() }}) / cast(nullif(destination_mar.total_monthly_active_rows,0) as {{ dbt.type_numeric() }}), 2) as credits_spent_per_million_mar,
        round( cast(nullif(destination_mar.total_monthly_active_rows,0) * 1.0 as {{ dbt.type_numeric() }}) / cast(nullif(usage.credits_spent,0) as {{ dbt.type_numeric() }}), 0) as mar_per_credit_spent,
        round( cast(nullif(usage.dollars_spent,0) * 1000000.0 as {{ dbt.type_numeric() }}) / cast(nullif(destination_mar.total_monthly_active_rows,0) as {{ dbt.type_numeric() }}), 2) as amount_spent_per_million_mar,
        round( cast(nullif(destination_mar.total_monthly_active_rows,0) * 1.0 as {{ dbt.type_numeric() }}) / cast(nullif(usage.dollars_spent,0) as {{ dbt.type_numeric() }}), 0) as mar_per_amount_spent
    from destination_mar 
    left join usage 
        on destination_mar.measured_month = cast(usage.measured_month as date)
        and destination_mar.destination_id = usage.destination_id
    left join transformation_runs
        on destination_mar.measured_month = transformation_runs.measured_month
        and destination_mar.destination_id = transformation_runs.destination_id

)

select * 
from join_usage_mar