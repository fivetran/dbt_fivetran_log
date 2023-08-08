with base as (
    
    select * 
    from {{ var('account') }}
),

fields as (

    select
        id as account_id,
        country,
        cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
        name as account_name,
        status
    from base
)

select * 
from fields