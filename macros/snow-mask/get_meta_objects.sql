{% macro get_meta_objects(node_unique_id, meta_key,node_resource_type="model") %}
	{% if execute %}

        {% set meta_columns = [] %}
        {% if node_resource_type == "source" %}
            {% set columns = graph.sources[node_unique_id]['columns'] %}
        {% else %}
            {% set columns = graph.nodes[node_unique_id]['columns'] %}
        {% endif %}

        {% if meta_key is not none %}
            {% for column in columns %}
                {# dbt >=1.10 moves column-level meta under `config.meta`; the old
                   column-root `meta` is deprecated. Merge both so the policy is
                   found wherever it is declared, with `config.meta` winning. #}
                {% set meta_dict = {} %}
                {% do meta_dict.update(columns[column].get('meta', {})) %}
                {% do meta_dict.update(columns[column].get('config', {}).get('meta', {})) %}

                {% if meta_dict.get(meta_key) %}
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
            {% do meta_columns.append(column|upper) %}
        {% endif %}

        {{ return(meta_columns) }}

    {% endif %}
{% endmacro %}
