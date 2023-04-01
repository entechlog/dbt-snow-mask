{% macro get_masking_policy_list_for_models(meta_key) %}

    {% set masking_policies = [] %}

    {% for node in graph.nodes.values() -%}

        {{ log(modules.datetime.datetime.now().strftime("%H:%M:%S") ~ " | macro - now processing            : " ~ node.unique_id | string , info=False) }}
        
        {% set node_database        = node.database | string %}
        {% set node_schema          = node.schema | string %}
        {% set node_unique_id       = node.unique_id | string %}
        {% set node_resource_type   = node.resource_type | string %}

        {% set meta_columns = dbt_snow_mask.get_meta_objects(node_unique_id,meta_key,node_resource_type) %}
    
        {%- for meta_tuple in meta_columns if meta_columns | length > 0 %}
            {{ log(modules.datetime.datetime.now().strftime("%H:%M:%S") ~ " | macro - meta_columns               : " ~ node_unique_id ~ " has " ~ meta_columns | string ~ " masking tags set", info=False) }}

            {% set column                           = meta_tuple[0] %}
            {% set masking_policy_name              = meta_tuple[1] %}
            {% set conditional_columns              = meta_tuple[2] %}
            {% if conditional_columns | length > 0 %}
                {% set conditionally_masked_column = column %}
            {% else %}
                {% set conditionally_masked_column = none %}
            {% endif %}
            {% if masking_policy_name is not none %}
                {% set masking_policy_tuple = (node_database, node_schema, masking_policy_name, conditionally_masked_column) %}
                {% do masking_policies.append(masking_policy_tuple) %}
            {% endif %}

        {% endfor %}
    
    {% endfor %}

    {{ return(masking_policies) }}

{% endmacro %}