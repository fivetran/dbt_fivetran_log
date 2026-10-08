{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- the end model has one row per completed sync; the joins should not fan out
with end_model as (
    select count(*) as row_count
    from {{ ref('fivetran_platform__sync_metrics') }}
),

staging_model as (
    select count(distinct sync_id) as row_count
    from {{ ref('stg_fivetran_platform__log') }}
    where event_subtype = 'sync_end'
        and sync_id is not null
)

select
    end_model.row_count as end_model_row_count,
    staging_model.row_count as staging_model_row_count
from end_model
cross join staging_model
where end_model.row_count != staging_model.row_count
