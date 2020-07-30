{% macro enable_model(table_name) %}
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

    {{ return( sources != [] ) }}

{% else %} 
return( false ) 
{% endif %} 
{% endmacro %}
