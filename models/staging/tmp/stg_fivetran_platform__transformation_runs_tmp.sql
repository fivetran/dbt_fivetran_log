-- If you have the transformation_runs and wish to enable this model, set the fivetran_platform_using_transformations variable within your dbt_project.yml file to True.
{{ config(enabled=var('fivetran_platform_using_transformations', False)) }}

select *
from {{ var('transformation_runs') }}