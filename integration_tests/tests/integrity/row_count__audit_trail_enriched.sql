
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- the enriched model resolves resource names via left joins and must remain 1:1 with the staging audit trail
with end_model as (

    select count(*) as row_count
    from {{ ref('fivetran_platform__audit_trail_enriched') }}
),

staging_model as (

    select count(*) as row_count
    from {{ ref('stg_fivetran_platform__audit_trail') }}
)

select
    end_model.row_count as end_model_row_count,
    staging_model.row_count as staging_model_row_count
from end_model
cross join staging_model
where end_model.row_count != staging_model.row_count
