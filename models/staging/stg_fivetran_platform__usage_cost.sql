{% if var('fivetran_platform__usage_pricing', does_table_exist('usage_cost')) %}
with base as (

    select * 
    from {{ var('usage_cost') }}
),

fields as (
    
    select 
        destination_id,
        measured_month,
        amount as dollars_spent
    from base
)

select * 
from fields

{% else %}

select
    cast(null as {{ dbt.type_string() }}) as destination_id,
    cast(null as {{ dbt.type_string() }}) as measured_month,
    cast(null as {{ dbt.type_int() }}) as dollars_spent

    {% if target.type in ('sqlserver') %}
    
    order by destination_id
    offset 0 rows 
    fetch next 0 rows only

    {% else %}

    limit 0

    {% endif %}

{% endif %}