with base as (

    select * 
    from {{ var('destination') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('fivetran_platform', 'destination')),
                staging_columns=get_destination_columns()
            )
        }}
    from base
),

final as (

    select
        id as destination_id,
        account_id,
        cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
        name as destination_name,
        region
    from fields
)

select * 
from final