{{ config(enabled=var('fivetran_platform_using_audit_trail', False)) }}

{% set source_columns_in_relation = adapter.get_columns_in_relation(source('fivetran_platform', 'audit_trail')) %}

with base as (

    select *
    from {{ var('audit_trail') }}
),

fields as (
    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=source_columns_in_relation,
                staging_columns=get_audit_trail_columns()
            )
        }}
    from base
),

field_conversion as (
    select
        *,
        {{ fivetran_log.json_to_string("old_values", source_columns_in_relation) }} as old_values_string,
        {{ fivetran_log.json_to_string("new_values", source_columns_in_relation) }} as new_values_string
    from fields
),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['id','captured_at']) }} as unique_audit_trail_key,
        id as audit_trail_id,
        cast(captured_at as {{ dbt.type_timestamp() }}) as captured_at,
        user_id,
        action,
        interaction_method,
        primary_resource_type,
        primary_resource_id,
        secondary_resource_type,
        secondary_resource_id,
        old_values_string as old_values,
        new_values_string as new_values,
        _fivetran_synced
    from field_conversion
)

select *
from final
