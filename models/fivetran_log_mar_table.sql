with mar_all_months as (

    select * 
    from {{ ref('fivetran_log_mar_table_history') }}

),

ordered_mar_months as (

    select 
        *,
        row_number() over(partition by table_name, connector_id, destination_id order by measured_month desc) as n
    
    from mar_all_months
),

latest_mar_month as (

    select 
        schema_name,
        table_name,
        connector_id, -- not actually connector.id
        connector_type,
        destination_id,
        destination_name,
        last_measured_at,
        measured_month as last_measured_month,
        sum(monthly_active_rows) as monthly_active_rows
    
    from ordered_mar_months
    where n = 1

    group by 1,2,3,4,5,6,7,8
)

select * from latest_mar_month