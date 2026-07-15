# Fivetran Platform dbt Package — Sample Queries

Replace `your_database.your_schema_fivetran_platform` with your actual database and schema name.
The output schema follows the pattern: `<your_database>.<connector_schema_name>_fivetran_platform`.

---

## fivetran_platform__connection_status

**Broken or unhealthy connections**
```sql
select
    connection_name,
    connector_type,
    destination_name,
    connection_health,
    last_successful_sync_completed_at,
    number_errors_since_last_completed_sync
from your_database.your_schema_fivetran_platform.fivetran_platform__connection_status
where connection_health != 'connected'
order by number_errors_since_last_completed_sync desc;
```

**Connections that have not synced successfully in the last 24 hours**
```sql
select
    connection_name,
    connector_type,
    destination_name,
    connection_health,
    last_successful_sync_completed_at
from your_database.your_schema_fivetran_platform.fivetran_platform__connection_status
where last_successful_sync_completed_at < current_timestamp - interval '24 hours'
   or last_successful_sync_completed_at is null
order by last_successful_sync_completed_at asc nulls first;
```

**Connections with the most schema changes in the last 30 days**
```sql
select
    connection_name,
    connector_type,
    destination_name,
    number_of_schema_changes_last_month
from your_database.your_schema_fivetran_platform.fivetran_platform__connection_status
where number_of_schema_changes_last_month > 0
order by number_of_schema_changes_last_month desc
limit 25;
```

---

## fivetran_platform__mar_table_history

**Top 25 tables by paid MAR for the most recent month**
```sql
select
    connection_name,
    schema_name,
    table_name,
    destination_name,
    measured_month,
    paid_monthly_active_rows,
    total_monthly_active_rows
from your_database.your_schema_fivetran_platform.fivetran_platform__mar_table_history
where measured_month = (select max(measured_month) from your_database.your_schema_fivetran_platform.fivetran_platform__mar_table_history)
order by paid_monthly_active_rows desc
limit 25;
```

**Monthly paid vs free MAR by connection**
```sql
select
    connection_name,
    destination_name,
    measured_month,
    sum(paid_monthly_active_rows) as paid_mar,
    sum(free_monthly_active_rows) as free_mar,
    sum(total_monthly_active_rows) as total_mar
from your_database.your_schema_fivetran_platform.fivetran_platform__mar_table_history
group by connection_name, destination_name, measured_month
order by connection_name, measured_month;
```

**Tables whose paid MAR grew month over month**
```sql
with monthly as (
    select
        connection_name,
        schema_name,
        table_name,
        measured_month,
        paid_monthly_active_rows,
        lag(paid_monthly_active_rows) over (
            partition by connection_name, schema_name, table_name
            order by measured_month
        ) as prior_month_paid_mar
    from your_database.your_schema_fivetran_platform.fivetran_platform__mar_table_history
)
select
    connection_name,
    schema_name,
    table_name,
    measured_month,
    paid_monthly_active_rows,
    prior_month_paid_mar,
    paid_monthly_active_rows - prior_month_paid_mar as mar_change
from monthly
where prior_month_paid_mar is not null
  and paid_monthly_active_rows > prior_month_paid_mar
order by mar_change desc;
```

---

## fivetran_platform__usage_history

**Monthly spend trend by destination**
```sql
select
    destination_name,
    measured_month,
    credits_spent,
    dollars_spent,
    total_monthly_active_rows
from your_database.your_schema_fivetran_platform.fivetran_platform__usage_history
order by destination_name, measured_month;
```

**Most expensive months by total credits spent**
```sql
select
    measured_month,
    sum(credits_spent) as total_credits_spent,
    sum(dollars_spent) as total_dollars_spent,
    sum(total_monthly_active_rows) as total_mar
from your_database.your_schema_fivetran_platform.fivetran_platform__usage_history
group by measured_month
order by total_credits_spent desc nulls last;
```

**Cost efficiency trend — credits spent per million MAR**
```sql
select
    destination_name,
    measured_month,
    credits_spent_per_million_mar,
    amount_spent_per_million_mar,
    total_monthly_active_rows
from your_database.your_schema_fivetran_platform.fivetran_platform__usage_history
where credits_spent_per_million_mar is not null
order by destination_name, measured_month;
```

---

## fivetran_platform__connection_daily_events

**Total record modifications per connection over the last 30 days**
```sql
select
    connection_name,
    connector_type,
    destination_name,
    sum(count_record_modifications) as total_record_modifications,
    sum(count_api_calls) as total_api_calls,
    sum(count_schema_changes) as total_schema_changes
from your_database.your_schema_fivetran_platform.fivetran_platform__connection_daily_events
where date_day >= current_date - interval '30 days'
group by connection_name, connector_type, destination_name
order by total_record_modifications desc;
```

**Days with unusually high schema changes**
```sql
select
    date_day,
    connection_name,
    destination_name,
    count_schema_changes
from your_database.your_schema_fivetran_platform.fivetran_platform__connection_daily_events
where count_schema_changes > 0
order by count_schema_changes desc
limit 50;
```

**API call volume by connector type over the last 7 days**
```sql
select
    connector_type,
    sum(count_api_calls) as total_api_calls
from your_database.your_schema_fivetran_platform.fivetran_platform__connection_daily_events
where date_day >= current_date - interval '7 days'
group by connector_type
order by total_api_calls desc;
```

---

## fivetran_platform__schema_changelog

**Most recent schema changes across all connections**
```sql
select
    created_at,
    connection_name,
    destination_name,
    event_subtype,
    schema_name,
    table_name
from your_database.your_schema_fivetran_platform.fivetran_platform__schema_changelog
order by created_at desc
limit 100;
```

**Schema change frequency by connection**
```sql
select
    connection_name,
    destination_name,
    event_subtype,
    count(*) as change_count
from your_database.your_schema_fivetran_platform.fivetran_platform__schema_changelog
group by connection_name, destination_name, event_subtype
order by change_count desc;
```

---

## fivetran_platform__audit_table

**Tables with the most total row modifications per sync**
```sql
select
    connection_name,
    schema_name,
    table_name,
    destination_name,
    write_to_table_start,
    sum_rows_replaced_or_inserted,
    sum_rows_updated,
    sum_rows_deleted,
    (sum_rows_replaced_or_inserted + sum_rows_updated + sum_rows_deleted) as total_rows_modified
from your_database.your_schema_fivetran_platform.fivetran_platform__audit_table
order by total_rows_modified desc
limit 50;
```

**Slowest tables to sync by write duration**
```sql
select
    connection_name,
    schema_name,
    table_name,
    destination_name,
    write_to_table_start,
    write_to_table_end,
    datediff('minute', write_to_table_start, write_to_table_end) as write_duration_minutes
from your_database.your_schema_fivetran_platform.fivetran_platform__audit_table
where write_to_table_end is not null
order by write_duration_minutes desc
limit 50;
```

---

## fivetran_platform__audit_user_activity

**Most active users by number of actions**
```sql
select
    email,
    first_name,
    last_name,
    count(*) as action_count
from your_database.your_schema_fivetran_platform.fivetran_platform__audit_user_activity
group by email, first_name, last_name
order by action_count desc;
```

**Most common action types**
```sql
select
    event_subtype,
    count(*) as occurrences
from your_database.your_schema_fivetran_platform.fivetran_platform__audit_user_activity
group by event_subtype
order by occurrences desc;
```

**Recent user activity feed**
```sql
select
    occurred_at,
    email,
    event_subtype,
    connection_name,
    destination_name,
    message_data
from your_database.your_schema_fivetran_platform.fivetran_platform__audit_user_activity
order by occurred_at desc
limit 100;
```

---

## fivetran_platform__audit_trail_enriched

*Requires Enterprise plan or above.*

**All changes made to connections in the last 30 days**
```sql
select
    captured_at,
    actor_email,
    action,
    primary_resource_name as connection_name,
    secondary_resource_name,
    old_values,
    new_values
from your_database.your_schema_fivetran_platform.fivetran_platform__audit_trail_enriched
where primary_resource_type = 'CONNECTION'
  and captured_at >= current_timestamp - interval '30 days'
order by captured_at desc;
```

**Most active users by audit trail action count**
```sql
select
    actor_email,
    actor_first_name,
    actor_last_name,
    count(*) as action_count
from your_database.your_schema_fivetran_platform.fivetran_platform__audit_trail_enriched
group by actor_email, actor_first_name, actor_last_name
order by action_count desc;
```

**Action summary — what types of changes are most common?**
```sql
select
    action,
    primary_resource_type,
    count(*) as occurrences
from your_database.your_schema_fivetran_platform.fivetran_platform__audit_trail_enriched
group by action, primary_resource_type
order by occurrences desc;
```

---

## fivetran_platform__transformation_run_log

**Failed transformation runs in the last 7 days**
```sql
select
    started_at,
    transformation_name,
    transformation_status,
    duration,
    failed_model_runs,
    successful_model_runs,
    destination_name,
    connection_names
from your_database.your_schema_fivetran_platform.fivetran_platform__transformation_run_log
where transformation_status in ('transformation_failed', 'transformation_partially_succeeded')
  and started_at >= current_timestamp - interval '7 days'
order by started_at desc;
```

**Average run duration per transformation**
```sql
select
    transformation_name,
    destination_name,
    count(*) as total_runs,
    avg(duration_seconds) as avg_duration_seconds,
    max(duration_seconds) as max_duration_seconds
from your_database.your_schema_fivetran_platform.fivetran_platform__transformation_run_log
group by transformation_name, destination_name
order by avg_duration_seconds desc;
```

**Transformations with the most cumulative failures**
```sql
select
    transformation_name,
    destination_name,
    sum(failed_model_runs) as total_failed_model_runs,
    sum(successful_model_runs) as total_successful_model_runs,
    count(*) as total_runs
from your_database.your_schema_fivetran_platform.fivetran_platform__transformation_run_log
group by transformation_name, destination_name
order by total_failed_model_runs desc;
```

---

## fivetran_platform__errors_and_warnings

**All severe errors in the last 24 hours**
```sql
select
    event_time,
    connection_name,
    severity_level,
    message,
    sync_id
from your_database.your_schema_fivetran_platform.fivetran_platform__errors_and_warnings
where lower(severity_level) = 'severe'
  and event_time >= current_timestamp - interval '24 hours'
order by event_time desc;
```

**Connections with the most errors in the last 7 days**
```sql
select
    connection_name,
    severity_level,
    count(*) as event_count
from your_database.your_schema_fivetran_platform.fivetran_platform__errors_and_warnings
where event_time >= current_timestamp - interval '7 days'
group by connection_name, severity_level
order by event_count desc;
```

**Most common error messages**
```sql
select
    message,
    severity_level,
    count(*) as occurrences
from your_database.your_schema_fivetran_platform.fivetran_platform__errors_and_warnings
group by message, severity_level
order by occurrences desc
limit 25;
```
