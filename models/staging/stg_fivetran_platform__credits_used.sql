{% if var('fivetran_platform__credits_pricing', does_table_exist('credits_used')) %}

with base as (

    select * 
    from {{ var('credits_used') }}
),

fields as (
    
    select 
        destination_id,
        measured_month,
        credits_consumed as credits_spent
    from base
)

select * 
from fields

{% else %}

select
    cast(null as {{ dbt.type_string() }}) as destination_id,
    cast(null as {{ dbt.type_string() }}) as measured_month,
    cast(null as {{ dbt.type_int() }}) as credits_spent

{% endif %}
