select *
from {{ var('log') }}
{% if var('fivetran_platform_lookback_window_months', none) is not none %}
where time_stamp >= cast({{ dbt.dateadd('month', -var('fivetran_platform_lookback_window_months', none), dbt.current_timestamp()) }} as {{ dbt.type_timestamp() }})
{% endif %}