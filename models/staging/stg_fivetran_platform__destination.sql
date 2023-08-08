with base as (

    select * 
    from {{ var('destination') }}
),

fields as (

    select
        id as destination_id,
        account_id,
        cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
        name as destination_name,
        region
    from base
)

select * 
from fields