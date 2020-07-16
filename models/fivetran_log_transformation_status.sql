with transformation as (

    select *
    from {{ ref('stg_fivetran_log_transformation') }}
),

destination as (

    select * 
    from {{ ref('stg_fivetran_log_destination') }}
),

transformation_runs as (

    select *
    from {{ ref('stg_fivetran_log_log') }}

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

    from 
    transformation 
    left join recent_runs 
        on recent_runs.transformation_id = transformation.transformation_id
    join destination 
        on destination.destination_id = transformation.destination_id
)


select * from transformation_join