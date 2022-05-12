{% if var('fivetran_log__usage_pricing', does_table_exist('usage_cost')) %}
with usage as (

    select * 
    from {{ var('usage_cost') }}
),

fields as (
    
    select 
        destination_id,
        measured_month,
        amount as dollars_spent
    from usage
)

select * 
from fields

{% else %}

select
    cast(null as {{ dbt_utils.type_string() }}) as destination_id,
    cast(null as {{ dbt_utils.type_string() }}) as measured_month,
    cast(null as {{ dbt_utils.type_int() }}) as dollars_spent

{% endif %}