{% if var('fivetran_platform__credits_pricing', does_table_exist('credits_used')) %}

with base as (

    select * 
    from {{ var('credits_used') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('fivetran_platform', 'credits_used')),
                staging_columns=get_credits_used_columns()
            )
        }}
    from base
),

final as (
    
    select 
        destination_id,
        measured_month,
        credits_consumed as credits_spent
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
    cast(null as {{ dbt.type_int() }}) as credits_spent

    {% if target.type not in ('sqlserver') %}
    limit {{ '1' if target.type == 'redshift' else '0' }}
    {% endif %}

{% endif %}
