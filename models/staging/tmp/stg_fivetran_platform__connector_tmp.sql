{{ config(enabled=var('fivetran_platform_using_connector', False)) -}}

select *
from {{ var('connector') }}