{% if var('fivetran_platform_using_transformations', does_table_exist('transformation_runs')) %}

with base as (

    select * 
    from {{ var('transformation_runs') }}
),

fields as (

    select
        _fivetran_synced,
        destination_id,
        upper(free_type) as free_type,
        job_id,
        job_name,
        cast(measured_date as {{ dbt.type_timestamp() }}) as measured_date,
        model_runs,
        project_type,
        updated_at
    from base
)

select
    *,
    cast({{ dbt.date_trunc('month', 'measured_date') }} as date) as measured_month
from fields

{% else %}

select

    {% if target.type in ('sqlserver') %}
    top 0
    {% endif %}

    cast(null as {{ dbt.type_timestamp() }}) as _fivetran_synced,
    cast(null as {{ dbt.type_string() }}) as destination_id,
    cast(null as {{ dbt.type_string() }}) as free_type,
    cast(null as {{ dbt.type_string() }}) as job_id,
    cast(null as {{ dbt.type_string() }}) as job_name,
    cast(null as {{ dbt.type_timestamp() }}) as measured_date,
    cast(null as {{ dbt.type_int() }}) as model_runs,
    cast(null as {{ dbt.type_string() }}) as project_type,
    cast(null as {{ dbt.type_timestamp() }}) as updated_at,
    cast(null as date) as measured_month

    {% if target.type not in ('sqlserver') %}
    limit {{ '1' if target.type == 'redshift' else '0' }}
    {% endif %}

{% endif %}