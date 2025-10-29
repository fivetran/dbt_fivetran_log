
{{ config(
    tags="fivetran_validations",
    enabled=var('fivetran_validation_tests_enabled', false)
) }}

with prod as (
    select
        connection_id,
        table_name,
        count(*) as total_records,
        sum(sum_rows_replaced_or_inserted) as sum_rows_replaced_or_inserted,
        sum(sum_rows_deleted) as sum_rows_deleted,
        sum(sum_rows_updated) as sum_rows_updated

    from {{ target.schema }}_fivetran_platform_prod.fivetran_platform__audit_table
    group by 1, 2
),

dev as (
    select
        connection_id,
        table_name,
        count(*) as total_records,
        sum(sum_rows_replaced_or_inserted) as sum_rows_replaced_or_inserted,
        sum(sum_rows_deleted) as sum_rows_deleted,
        sum(sum_rows_updated) as sum_rows_updated

    from {{ target.schema }}_fivetran_platform_dev.fivetran_platform__audit_table
    group by 1, 2
),

final_consistency_check as (
    select 
        prod.connection_id,
        prod.table_name,
        prod.total_records as prod_total,
        dev.total_records as dev_total,
        prod.sum_rows_replaced_or_inserted as prod_sum_rows_replaced_or_inserted,
        dev.sum_rows_replaced_or_inserted as dev_sum_rows_replaced_or_inserted,
        prod.sum_rows_deleted as prod_sum_rows_deleted,
        dev.sum_rows_deleted as dev_sum_rows_deleted,
        prod.sum_rows_updated as prod_sum_rows_updated,
        dev.sum_rows_updated as dev_sum_rows_updated

    from prod
    left join dev 
        on dev.connection_id = prod.connection_id
        and dev.table_name = prod.table_name
),

-- Checking to ensure the dev totals match the prod totals
consistency_check as (
    select *
    from final_consistency_check
    where prod_total != dev_total
    or prod_sum_rows_replaced_or_inserted != dev_sum_rows_replaced_or_inserted
    or prod_sum_rows_deleted != dev_sum_rows_deleted
    or prod_sum_rows_updated != dev_sum_rows_updated
),

-- For use when the current release changes the row count of the audit table model intentionally.
-- The below queries prove the records that do not match are still accurate by checking the source.
verification_staging_setup as (
    select
        connection_id, 
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
        on consistency_check.connection_id = verification_staging_setup.connection_id
        and consistency_check.table_name = verification_staging_setup.table_name
    where consistency_check.dev_total != verification_staging_setup.row_count
)

select *
from final_verification

