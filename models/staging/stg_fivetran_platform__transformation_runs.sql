
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
    from base
),

final as (
    
    select
        _fivetran_synced,
        destination_id,
        upper(free_type) as free_type,
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
    cast({{ dbt.date_trunc('month', 'measured_date') }} as date) as measured_month
from final
