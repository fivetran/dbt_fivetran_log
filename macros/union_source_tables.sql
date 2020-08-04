{% macro union_source_tables(table_name) %}
    {% if execute %}
        {%- set sources = [] -%}

        -- look at the declared source tables 
        {%- for node in graph.sources.values() -%}

            -- call the database for the matching table
            {%- set source_relation = adapter.get_relation(
                    database=node.database,
                    schema=node.schema,
                    identifier=node.name ) -%} 

            {%- if source_relation != None and node.name == table_name -%} 
                {%- do sources.append(source(node.source_name, node.name)) -%}
            {%- endif -%}
        {%- endfor -%}

        {%- for source in sources %}
            select *,  
            {{ "'" ~ source.database ~ "'"}} as destination_database 
            from {{ source }} 
            {%- if not loop.last -%} union all {%- endif -%}

        {%- endfor -%} 

        {%- if sources == [] %} 
            select 
            -- these are the only tables that should possibly not exist
            {% if table_name == 'trigger_table' %}
                cast(null as {{ dbt_utils.type_string() }}) as table,
                cast(null as {{ dbt_utils.type_string() }}) as transformation_id,
            
            {% elif table_name == 'transformation' %}
                cast(null as {{ dbt_utils.type_string() }}) as transformation_id,
                cast(null as {{ dbt_utils.type_string() }}) as created_at,
                cast(null as {{ dbt_utils.type_string() }}) as created_by_user_id,
                cast(null as timestamp) as destination_id,
                cast(null as {{ dbt_utils.type_string() }}) as transformation_name,
                cast(null as boolean ) as is_paused,
                cast(null as {{ dbt_utils.type_string() }}) as script,
                cast(null as {{ dbt_utils.type_string() }}) as trigger_delay,
                cast(null as {{ dbt_utils.type_string() }}) as trigger_interval,
                cast(null as {{ dbt_utils.type_string() }}) as trigger_type,
            
            {% endif %}

                cast(null as {{ dbt_utils.type_string() }}) as destination_database

        {%- endif -%}
    
    {%- endif -%} 
{% endmacro %}