{{ config(enabled=var('fivetran_log_using_transformations', True)) }}

with transformation as (

    select *
    from {{ ref('stg_fivetran_log__transformation') }}
),

destination as (

    select * 
    from {{ ref('stg_fivetran_log__destination') }}
),

{% if var('fivetran_log_using_triggers', True) %}
trigger_tables as (

    select 
        transformation_id, 
        {{ fivetran_utils.string_agg("trigger_table", "', '") }} as trigger_tables 

    from {{ ref('stg_fivetran_log__trigger_table') }}

    group by 1
),
{% endif %}

transformation_runs as (

    select *
    from {{ ref('stg_fivetran_log__log') }}

    where event_subtype = 'transformation run success' 
        or event_subtype = 'transformation run failed' 
),

recent_runs as (

    select 
        transformation_id,
        max(case when event_subtype = 'transformation run success'  then created_at else null end) as last_run_at,
        max(case when event_subtype = 'transformation run failed'  then created_at else null end) as last_failure_at
    
    from transformation_runs
    group by 1
),

transformation_join as (

    select
        transformation.*,
        destination.destination_name,
        recent_runs.last_run_at as last_successful_run_at,
        case when recent_runs.last_run_at > recent_runs.last_failure_at or recent_runs.last_failure_at is null then 'success'
        else 'failure' end as last_run_attempt
        {% if var('fivetran_log_using_triggers', True) %}
        ,
        trigger_tables.trigger_tables
        {% endif %}

    from 
    transformation 
    join destination 
        on destination.destination_id = transformation.destination_id

    {% if var('fivetran_log_using_triggers', True) %}   
    left join trigger_tables
        on trigger_tables.transformation_id = transformation.transformation_id
    {% endif %}

    left join recent_runs 
        on recent_runs.transformation_id = transformation.transformation_id

)


select * from transformation_join