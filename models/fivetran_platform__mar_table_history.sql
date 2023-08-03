with incremental_mar as (

    select
        *,
        {{ dbt.date_trunc('month', 'measured_date') }} as measured_month

    from {{ ref('stg_fivetran_platform__incremental_mar') }}
),

connector as (

    select *
    from {{ ref('stg_fivetran_platform__connector') }}
),

destination as (

    select *
    from {{ ref('stg_fivetran_platform__destination') }}
),

ordered_mar as (

    select
        connector_name,
        schema_name,
        table_name,
        destination_id,
        measured_month,
        max(measured_date) as last_measured_at,
        sum(incremental_rows) as incremental_rows,
        sum(coalesce(case when lower(free_type) = 'paid'
            then incremental_rows
        end, 0)) as paid_monthly_active_rows,
        sum(coalesce(case when lower(free_type) != 'paid'
            then incremental_rows
        end, 0)) as free_monthly_active_rows

    from incremental_mar
    {{dbt_utils.group_by(5)}}
),

latest_mar as (
    select 
        connector_name,
        schema_name,
        table_name,
        destination_id,
        measured_month,
        date(last_measured_at) as last_measured_at,
        free_monthly_active_rows,
        paid_monthly_active_rows,
        (free_monthly_active_rows + paid_monthly_active_rows) as total_monthly_active_rows

    from ordered_mar
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

