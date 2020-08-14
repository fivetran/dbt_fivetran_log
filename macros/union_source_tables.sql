{% macro union_source_tables(table_name) %}
    {% if execute %}
        {%- set sources = [] -%}
        -- look at the declared source tables 
        {%- for node in graph.sources.values() -%}
        -- call the database for the matching tables
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
            {%- if not loop.last %} union all {%- endif %}

        {%- endfor -%} 

        {%- if sources == [] %} 
            select 
            -- these are the only tables that should possibly not exist
            {% if table_name == 'trigger_table' -%}
            {% if target.type == 'bigquery' -%}
                cast(null as {{ type_string() }}) as table, 
            {% else -%} 
                cast(null as {{ type_string() }}) as "TABLE",
            {% endif -%}
                cast(null as {{ type_string() }}) as transformation_id,
            {% elif table_name == 'transformation' -%}
                cast(null as {{ type_string() }}) as id,
                cast(null as timestamp) as created_at,
                cast(null as {{ type_string() }}) as created_by_id,
                cast(null as {{ type_string() }}) as destination_id,
                cast(null as {{ type_string() }}) as name,
                cast(null as boolean ) as paused,
                cast(null as {{ type_string() }}) as script,
                cast(null as {{ type_string() }}) as trigger_delay,
                cast(null as {{ type_string() }}) as trigger_interval,
                cast(null as {{ type_string() }}) as trigger_type,
            {% endif -%}
                cast(null as {{ type_string() }}) as destination_database

        {%- endif -%}
    
    {%- endif -%} 
{% endmacro %}