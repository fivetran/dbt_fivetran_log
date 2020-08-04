with user as (
    
    {{ union_source_tables('user') }}

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
        verified as is_verified,
        {{ string_agg( 'destination_database', "', '") }} as destination_databases
        
    from user
    group by 1,2,3,4,5,6,7,8
)

select * from fields