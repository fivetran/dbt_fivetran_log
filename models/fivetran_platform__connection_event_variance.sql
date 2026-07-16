with log as (

    select *
    from {{ ref('stg_fivetran_platform__log') }}
),

-- pull the day, weekday, and event subtype for each log record
parsed as (

    select
        log_id,
        connection_id,
        event_subtype,
        cast({{ dbt.date_trunc('day', 'created_at') }} as date) as date_day,

        {% if target.type != 'sqlserver' -%}
        {{ fivetran_log.fivetran_day_name('created_at', short=False) }} as day_of_week
        {% else -%}
        format(cast(created_at as date), 'dddd') as day_of_week
        {% endif -%}

    from log
    where connection_id is not null
),

-- count events per connection, event subtype, and day
daily_events as (

    select
        connection_id,
        event_subtype,
        date_day,
        day_of_week,
        count(log_id) as total_events

    from parsed
    group by connection_id, event_subtype, date_day, day_of_week
),

-- average daily event volume and standard deviation per connection, event subtype, and weekday
event_averages as (

    select
        connection_id,
        event_subtype,
        day_of_week,
        round(avg(cast(total_events as {{ dbt.type_float() }}))) as average_event_count,

        {% if target.type != 'sqlserver' -%}
        round(stddev_pop(cast(total_events as {{ dbt.type_float() }}))) as standard_deviation
        {% else -%}
        round(stdevp(cast(total_events as {{ dbt.type_float() }}))) as standard_deviation
        {% endif -%}

    from daily_events
    group by connection_id, event_subtype, day_of_week
),

-- attach each day's count to its weekday average and derive the variance band using the configurable knobs
joined as (

    select
        {{ dbt_utils.generate_surrogate_key(['daily_events.connection_id', 'daily_events.event_subtype', 'daily_events.date_day']) }} as connection_event_day_key,
        daily_events.date_day,
        daily_events.day_of_week,
        daily_events.connection_id,
        daily_events.event_subtype,
        daily_events.total_events,
        event_averages.average_event_count,
        round(event_averages.average_event_count + event_averages.average_event_count * {{ var('fivetran_platform_event_high_variance_percent') }}) as high_event_variance_value,
        round(event_averages.average_event_count - event_averages.average_event_count * {{ var('fivetran_platform_event_low_variance_percent') }}) as low_event_variance_value,
        round(event_averages.average_event_count * {{ var('fivetran_platform_event_high_variance_percent') }}) as high_event_variance_increment,
        round(event_averages.average_event_count * {{ var('fivetran_platform_event_low_variance_percent') }}) as low_event_variance_increment,
        event_averages.standard_deviation

    from daily_events
    left join event_averages
        on daily_events.connection_id = event_averages.connection_id
        and daily_events.event_subtype = event_averages.event_subtype
        and daily_events.day_of_week = event_averages.day_of_week
),

-- flag any day whose event volume falls outside the connection's typical weekday band
final as (

    select
        *,
        case
            when total_events > high_event_variance_value then 'event_variance'
            when total_events < low_event_variance_value then 'event_variance'
            else 'standard'
        end as event_variance_flag

    from joined
)

select *
from final
