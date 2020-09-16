with active_volume as (

    {% if var('unioning_multiple_destinations', false) is true %}
    {{ union_source_tables('active_volume') }}

    {% else %}
    select * from {{ var('active_volume') }}
    
    {% endif %}
),

fields as (

    select
        id as active_volume_id,
        connector_id as connector_name, -- Note: this misnomer will be changed by Fivetran soon.
        destination_id,
        measured_at,
        monthly_active_rows,
        schema_name,
        table_name,

        {% if var('unioning_multiple_destinations', false) is true -%}
        destination_database
        {% else -%}
        {{ "'" ~ var('fivetran_log_database', target.database) ~ "'" }} 
        {%- endif %} as destination_database
    
    from active_volume
)

select * from fields