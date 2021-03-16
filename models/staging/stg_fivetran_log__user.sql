with fivetran_user as (

    select * from {{ var('user') }}

),

fields as (

    select
        id as user_id,
        created_at,
        email,
        email_disabled as has_disabled_email_notifications,
        family_name as last_name,
        given_name as first_name,
        phone,
        verified as is_verified
        
    from fivetran_user

)

select * from fields