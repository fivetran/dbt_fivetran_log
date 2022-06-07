{% if var('fivetran_log__usage_pricing', does_table_exist('credits_used')) %}

with credits_used as (

    select * 
    from {{ var('credits_used') }}
),

fields as (
    
    select 
        destination_id,
        measured_month,
        credits_consumed as credits_spent
    from credits_used
)

select * 
from fields

{% else %}

select
    cast(null as {{ dbt_utils.type_string() }}) as destination_id,
    cast(null as {{ dbt_utils.type_string() }}) as measured_month,
    cast(null as {{ dbt_utils.type_int() }}) as credits_spent

{% endif %}
