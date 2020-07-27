{% macro union_source_tables(table_name) %}
    {% if execute %}
        {% set sources = [] -%}
        {% for node in graph.sources.values() -%}
            {%- if node.name == table_name -%}
                {%- do sources.append(source(node.source_name, node.name)) -%}
            {%- endif -%}
        {%- endfor %}

    

        {%- for source in sources %}
            select *,  {{ "'" ~ source.name ~ "'"}}  from 
            {{ source }} {% if not loop.last %} union all {% endif %}
        {% endfor %}
    
    {% else %} select 0 
    {% endif %} 
{% endmacro %}