with base as (
    
    select * 
    from {{ var('account') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('fivetran_platform', 'account')),
                staging_columns=get_account_columns()
            )
        }}
    from base
),

final as (

    select
        id as account_id,
        country,
        cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
        name as account_name,
        status
    from fields
)

select * 
from fields