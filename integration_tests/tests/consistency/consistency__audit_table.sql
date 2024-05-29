
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        connector_id,
        table_name,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__audit_table
    group by 1, 2
),

dev as (
    select
        connector_id,
        table_name,
        count(*) as total_records
    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__audit_table
    group by 1, 2
),

final_consistency_check as (
    select 
        prod.connector_id,
        prod.table_name,
        prod.total_records as prod_total,
        dev.total_records as dev_total
    from prod
    left join dev 
        on dev.connector_id = prod.connector_id
        and dev.table_name = prod.table_name
),

-- Checking to ensure the dev totals match the prod totals
consistency_check as (
    select *
    from final_consistency_check
    where prod_total != dev_total
),

-- The current release changes the row count of the audit table model intentionally.
-- The below queries prove the records that do not match are still accurate by checking the source.
verification_staging_setup as (
    select
        connector_id, 
        {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['table']) }} as table_name,
        count(*) as row_count
    from {{ target.schema }}_fivetran_platform_dev.stg_fivetran_platform__log
    where event_subtype in ('write_to_table_start')
    group by 1, 2
),

final_verification as (
    select *
    from consistency_check
    left join verification_staging_setup
        on consistency_check.connector_id = verification_staging_setup.connector_id
        and consistency_check.table_name = verification_staging_setup.table_name
    where consistency_check.dev_total != verification_staging_setup.row_count
)

select *
from final_verification

