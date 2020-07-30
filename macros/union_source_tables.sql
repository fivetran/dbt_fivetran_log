{% macro union_source_tables(table_name) %}
    {% if execute %}
        {%- set sources = [] -%}
        {%- for node in graph.sources.values() -%}

            {%- set source_relation = adapter.get_relation(
                    database=node.database,
                    schema=node.schema,
                    identifier=table_name ) -%} -- todo: for some reason it's totally ignoring the identifier

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
            select null as destination_database 
        {%- endif -%}
    
    {%- endif -%} 
{% endmacro %}

-- iterate through defined sources
-- take their database 
-- check if the database-table relation != none from adapter.get_relation
-- store the databases that have the table
-- union their tables