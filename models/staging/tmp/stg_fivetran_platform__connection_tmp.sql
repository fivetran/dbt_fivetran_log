select *
from {{ var('connection' if var('fivetran_platform_using_connection', True) else 'connector') }}