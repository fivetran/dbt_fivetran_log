with log as (

    select *
    from {{ ref('stg_fivetran_platform__log') }}
),

-- limit to records_modified events and normalize the camelCase operationType key before parsing
base as (

    select
        log_id,
        connection_id,
        created_at,
        replace(message_data, 'operationType', 'operation_type') as message_data

    from log
    where event_subtype = 'records_modified'
),

-- pull the day, weekday, table, operation, and row count out of each record modification event
parsed as (

    select
        log_id,
        connection_id,
        created_at,
        cast({{ dbt.date_trunc('day', 'created_at') }} as date) as date_day,

        {% if target.type != 'sqlserver' -%}
        {{ fivetran_log.fivetran_day_name('created_at', short=False) }} as day_of_week,
        {% else -%}
        format(cast(created_at as date), 'dddd') as day_of_week,
        {% endif -%}

        {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['table']) }} as table_name,
        {{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['operation_type']) }} as operation_type,
        cast({{ fivetran_log.fivetran_log_json_parse(string='message_data', string_path=['count']) }} as {{ dbt.type_bigint() }}) as rows_modified

    from base
),

-- exclude the Fivetran audit table, which is internal bookkeeping rather than synced data
filtered as (

    select *
    from parsed
    where table_name != 'fivetran_audit'
),

-- average rows modified and standard deviation per connection, table, operation, and weekday
records_modified_averages as (

    select
        connection_id,
        table_name,
        operation_type,
        day_of_week,
        round(avg(cast(rows_modified as {{ dbt.type_float() }}))) as average_rows_modified,

        {% if target.type != 'sqlserver' -%}
        coalesce(round(stddev_pop(cast(rows_modified as {{ dbt.type_float() }}))), 0) as standard_deviation
        {% else -%}
        coalesce(round(stdevp(cast(rows_modified as {{ dbt.type_float() }}))), 0) as standard_deviation
        {% endif -%}

    from filtered
    group by connection_id, table_name, operation_type, day_of_week
),

-- attach each event to its weekday average and derive the variance band using the configurable knobs
joined as (

    select
        {{ dbt_utils.generate_surrogate_key(['filtered.connection_id', 'filtered.log_id', 'filtered.table_name', 'filtered.operation_type']) }} as records_modified_variance_key,
        filtered.date_day,
        filtered.day_of_week,
        filtered.created_at,
        filtered.connection_id,
        filtered.table_name,
        filtered.operation_type,
        filtered.rows_modified,
        averages.average_rows_modified,
        round(averages.average_rows_modified + averages.average_rows_modified * {{ var('fivetran_platform_records_modified_high_variance_percent') }}) as high_variance_value,
        round(averages.average_rows_modified - averages.average_rows_modified * {{ var('fivetran_platform_records_modified_low_variance_percent') }}) as low_variance_value,
        round(averages.average_rows_modified * {{ var('fivetran_platform_records_modified_high_variance_percent') }}) as high_variance_increment,
        round(averages.average_rows_modified * {{ var('fivetran_platform_records_modified_low_variance_percent') }}) as low_variance_increment,
        averages.standard_deviation

    from filtered
    left join records_modified_averages as averages
        on filtered.connection_id = averages.connection_id
        and filtered.table_name = averages.table_name
        and filtered.operation_type = averages.operation_type
        and filtered.day_of_week = averages.day_of_week
),

-- flag any event whose row count falls outside the table's typical weekday band
final as (

    select
        *,
        case
            when rows_modified > high_variance_value then 'variance'
            when rows_modified < low_variance_value then 'variance'
            else 'standard'
        end as variance_flag

    from joined
)

select *
from final
