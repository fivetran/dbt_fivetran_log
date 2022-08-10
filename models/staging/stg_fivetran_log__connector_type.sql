
with connector_type as (
    select
        *
    from
        {{ var('connector_type') }}
    )

, fields as (

    select
        id as connector_type_id
        , official_connector_name as connector
        , type as connector_type
        , availability
        , created_at
        , public_beta_at
        , release_at
        , deleted as is_deleted
        , broken as is_broken
    from
        connector_type

    )

select * from fields