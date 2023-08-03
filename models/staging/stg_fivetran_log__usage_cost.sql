{% if var('fivetran_log__base_pricing', does_table_exist('base_cost')) %}
with base as (

    select * 
    from {{ var('base_cost') }}
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

{% endif %}