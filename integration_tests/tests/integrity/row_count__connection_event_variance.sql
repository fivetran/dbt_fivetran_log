{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

-- the end model has one row per connection, event subtype, and day; the joins should not fan out
with end_model as (
    select count(*) as row_count
    from {{ ref('fivetran_platform__connection_event_variance') }}
),

staging_model as (
    select count(*) as row_count
    from (
        select distinct
            connection_id,
            event_subtype,
            cast({{ dbt.date_trunc('day', 'created_at') }} as date) as date_day
        from {{ ref('stg_fivetran_platform__log') }}
        where connection_id is not null
    ) as distinct_events
)

select
    end_model.row_count as end_model_row_count,
    staging_model.row_count as staging_model_row_count
from end_model
cross join staging_model
where end_model.row_count != staging_model.row_count
