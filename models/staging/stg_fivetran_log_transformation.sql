{% set union_source_tables_query = union_source_tables('transformation') %}
{% set enable_model = 'select null as destination_database' not in ("'" ~ union_source_tables_query ~ "'") %}

with transformation as (
    
    {{ union_source_tables_query }}

),

fields as (

    select
        id as transformation_id,
        created_at,
        created_by_id as created_by_user_id,
        destination_id,
        name as transformation_name,
        paused as is_paused,
        script,
        trigger_delay,
        trigger_interval,
        trigger_type,
        source_destination
        
    from transformation
)

select * from fields