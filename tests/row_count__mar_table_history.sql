
{{ config(
    tags="validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with end_model as (
    select 
        connector_name,
        schema_name,
        table_name,
        destination_id,
        measured_month,
        total_monthly_active_rows as mar_count
    from {{ ref('fivetran_platform__mar_table_history') }}
),

staging_model as (
    select
        connector_name,
        schema_name,
        table_name,
        destination_id,
        {{ dbt.date_trunc('month', 'measured_date') }} as measured_month,
        sum(incremental_rows) as mar_count
    from {{ ref('stg_fivetran_platform__incremental_mar') }}
    group by connector_name, schema_name, table_name, destination_id, {{ dbt.date_trunc('month', 'measured_date') }} as measured_month
)

select 
    end_model.connector_name,
    end_model.schema_name,
    end_model.destination_id,
    end_model.measured_month,
    end_model.mar_count as end_model_mar_count,
    staging_model.mar_count as staging_model_mar_count
from end_model
left join staging_model
    on end_model.connector_name = staging_model.connector_name
    and end_model.schema_name = staging_model.schema_name
    and end_model.table_name = staging_model.table_name
    and end_model.destination_id = staging_model.destination_id
    and end_model.measured_month = staging_model.measured_month
where staging_model.mar_count != end_model.mar_count