{{ config(enabled=fivetran_utils.enabled_vars(['fivetran_log_credits_used'])) }}

with  credits_used as (

    select * from {{ var('credits_used') }}

),

fields as (
    
    select 
        destination_id,
        measured_month,
        credits_consumed
    
    from credits_used
)

select * from fields
