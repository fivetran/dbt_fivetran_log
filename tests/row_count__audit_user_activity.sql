{{ config(
    tags="validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with end_model as (
    select 
        connector_id, 
        email,
        date_day,
        count(*) as row_count
    from {{ ref('fivetran_platform__audit_user_activity') }}
    group by 1, 2, 3
),

staging_model as (

    select 
        *,
        {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['actor']) }} as email
    from {{ ref('stg_fivetran_platform__log') }}
    where lower(message_data) like '%actor%'
),

staging_cleanup as (

    select 
        connector_id,
        email,
        {{ dbt.date_trunc('day', 'created_at') }} as date_day,
        count(*) as row_count
    from staging_model
    where email is not null 
        and lower(email) != 'fivetran'
    group by 1,2,3
)

select 
    end_model.connector_id,
    end_model.email,
    end_model.date_day,
    end_model.row_count as end_model_row_count,
    staging_cleanup.row_count as staging_model_row_count
from end_model
left join staging_cleanup
    on end_model.connector_id = staging_cleanup.connector_id
    and end_model.email = staging_cleanup.email
    and end_model.date_day = staging_cleanup.date_day
where staging_cleanup.row_count != end_model.row_count