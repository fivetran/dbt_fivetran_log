
with base as (

    select * from {{ var('transformation_runs') }}
),

fields as (

    select
        _fivetran_synced,
        destination_id,
        free_type,
        job_id,
        job_name,
        measured_date,
        model_runs,
        project_type,
        updated_at
    from base
)

select *
from fields
