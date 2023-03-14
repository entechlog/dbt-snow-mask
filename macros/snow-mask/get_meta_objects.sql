{% macro get_meta_objects(node_unique_id, meta_key,node_resource_type="model") %}
	{% if execute %}

        {% set meta_columns = [] %}
        {% if node_resource_type == "source" %} 
            {% set columns = graph.sources[node_unique_id]['columns']  %}
        {% else %}
            {% set columns = graph.nodes[node_unique_id]['columns']  %}
        {% endif %}
        
        {% if meta_key is not none %}
            {% if node_resource_type == "source" %} 
                {% for column in columns if graph.sources[node_unique_id]['columns'][column]['meta'][meta_key] | length > 0 %}
                    {% set meta_dict = graph.sources[node_unique_id]['columns'][column]['meta'] %}
                    {% if meta_key in meta_dict %}
                        {% set policy_name = meta_dict[meta_key] %}
                        {% if "mp_conditional_columns" in meta_dict %}
                            {% set conditional_columns = meta_dict['mp_conditional_columns'] %}
                        {% else %}
                            {% set conditional_columns = [] %}
                        {% endif %}
                        {% set meta_tuple = (column, policy_name, conditional_columns) %}
                        {% do meta_columns.append(meta_tuple) %}
                    {% endif %}
                {% endfor %}
            {% else %}
                {% for column in columns if graph.nodes[node_unique_id]['columns'][column]['meta'][meta_key] | length > 0 %}
                    {% set meta_dict = graph.nodes[node_unique_id]['columns'][column]['meta'] %}
                    {% if meta_key in meta_dict %}
                        {% set policy_name = meta_dict[meta_key] %}
                        {% if "mp_conditional_columns" in meta_dict %}
                            {% set conditional_columns = meta_dict['mp_conditional_columns'] %}
                        {% else %}
                            {% set conditional_columns = [] %}
                        {% endif %}
                        {% set meta_tuple = (column, policy_name, conditional_columns) %}
                        {% do meta_columns.append(meta_tuple) %}
                    {% endif %}
                {% endfor %}
            {% endif %}
        {% else %}
            {% do meta_columns.append(column|upper) %}
        {% endif %}

        {{ return(meta_columns) }}

    {% endif %}
{% endmacro %}