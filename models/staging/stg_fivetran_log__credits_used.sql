{% if var('fivetran_log__usage_pricing', does_table_exist('usage_cost')) %}
with usage as (

    select * 
    from {{ var('usage_cost') }}

),

fields as (
    
    select 
        destination_id,
        measured_month,
        amount as consumption_amount
    
    from usage
)

select * 
from fields

{% else %}

with credits_used as (

    select * 
    from {{ var('credits_used') }}

),

fields as (
    
    select 
        destination_id,
        measured_month,
        credits_consumed as consumption_amount
    
    from credits_used
)

select * 
from fields

{% endif %}
