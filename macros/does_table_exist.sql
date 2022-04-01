{%- macro does_table_exist(table_name) -%}
    {%- if execute -%}
    {%- set ns = namespace(has_table=false) -%}
        {%- for node in graph.sources.values() -%}
        -- call the database for the matching table
            {%- set source_relation = adapter.get_relation(
                    database=node.database,
                    schema=node.schema,
                    identifier=node.name ) -%} 
            {%- if source_relation == None and node.name == table_name -%} 
                {{ return(False) }}
            {%- elif source_relation != None and node.name == table_name -%} 
                {{ return(True) }}
            {% endif %}
        {%- endfor -%}
    {%- endif -%} 
{%- endmacro -%}