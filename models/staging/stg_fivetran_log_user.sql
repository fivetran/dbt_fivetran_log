with user as (
    
    select * 
    from {{ var('user') }}

    -- union tables from multiple destinations here
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
        
    from user
)

select * from fields