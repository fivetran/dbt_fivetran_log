{% if var('fivetran_platform__usage_pricing', does_table_exist('usage_cost')) %}
with base as (

    select * 
    from {{ var('usage_cost') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('fivetran_platform', 'usage_cost')),
                staging_columns=get_usage_cost_columns()
            )
        }}
    from base
),

final as (
    
    select 
        destination_id,
        measured_month,
        amount as dollars_spent
    from fields
)

select * 
from final

{% else %}

select
   
    {% if target.type in ('sqlserver') %}
    top 0
    {% endif %}

    cast(null as {{ dbt.type_string() }}) as destination_id,
    cast(null as {{ dbt.type_string() }}) as measured_month,
    cast(null as {{ dbt.type_int() }}) as dollars_spent

    {% if target.type not in ('sqlserver') %}
    limit {{ '1' if target.type == 'redshift' else '0' }}
    {% endif %}

{% endif %}