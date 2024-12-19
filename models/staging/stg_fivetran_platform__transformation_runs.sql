
with base as (

    select * 
    from {{ ref('stg_fivetran_platform__transformation_runs_tmp') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_fivetran_platform__transformation_runs_tmp')),
                staging_columns=get_transformation_runs_columns()
            )
        }}
        {{ fivetran_utils.source_relation(
            union_schema_variable='fivetran_platform_union_schemas', 
            union_database_variable='fivetran_platform_union_databases') 
        }}
    from base
),

final as (
    
    select
        _fivetran_synced,
        destination_id,
        free_type,
        job_id,
        job_name,
        cast(measured_date as {{ dbt.type_timestamp() }}) as measured_date,
        model_runs,
        project_type,
        updated_at
    from fields
)

select
    *,
    {{ dbt.date_trunc('month', 'measured_date') }} as measured_month
from final
