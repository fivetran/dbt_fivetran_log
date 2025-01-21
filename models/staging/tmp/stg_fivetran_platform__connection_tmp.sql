{{ config(enabled=var('fivetran_platform_using_connection', True)) -}}

select *
from {{ var('connection') }}