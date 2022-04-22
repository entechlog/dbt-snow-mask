{% macro apply_masking_policy_list_for_models(meta_key,operation_type="apply") %}

    {% if operation_type == "apply" %}
    
        {% set model_id = model.unique_id | string %}
        {% set alias    = model.alias %}    
        {% set database = model.database %}
        {% set schema   = model.schema %}
        {% set materialization = model.config.get("materialized") %}
        {% if materialization == "incremental" %}
            {% set materialization = "table" %}
        {% endif %}
        {% set meta_columns = dbt_snow_mask.get_meta_objects(model_id,meta_key) %}

        {% set masking_policy_db = model.database %}
        {% set masking_policy_schema = model.schema %}
		
        {# Override the database and schema name when use common_masking_policy_db flag is set #}
        {%- if (var('use_common_masking_policy_db')|upper == 'TRUE') or (var('use_common_masking_policy_db')|upper == 'YES') -%}
            {% if var('common_masking_policy_db') and var('common_masking_policy_schema') %}
                {% set masking_policy_db = var('common_masking_policy_db') | string  %}
                {% set masking_policy_schema = var('common_masking_policy_schema') | string  %}
            {% endif %}
        {% endif %}

        {% set masking_policy_list_sql %}     
            show masking policies in {{masking_policy_db}}.{{masking_policy_schema}};
            select $3||'.'||$4||'.'||$2 as masking_policy from table(result_scan(last_query_id()));
        {% endset %}

        {%- for meta_tuple in meta_columns if meta_columns | length > 0 %}
            {% set column   = meta_tuple[0] %}
            {% set masking_policy_name  = meta_tuple[1] %}
                {% if masking_policy_name is not none %}

                {% set masking_policy_list = dbt_utils.get_query_results_as_dict(masking_policy_list_sql) %}

                {% for masking_policy_in_db in masking_policy_list['MASKING_POLICY'] %}
                    {% if masking_policy_db|upper ~ '.' ~ masking_policy_schema|upper ~ '.' ~ masking_policy_name|upper == masking_policy_in_db %}
                        {{ log(modules.datetime.datetime.now().strftime("%H:%M:%S") ~ " | " ~ operation_type ~ "ing masking policy to model  : " ~ masking_policy_db|upper ~ '.' ~ masking_policy_schema|upper ~ '.' ~ masking_policy_name|upper ~ " on " ~ database ~ '.' ~ schema ~ '.' ~ alias ~ '.' ~ column, info=True) }}
                        {% set query %}
                        alter {{materialization}}  {{database}}.{{schema}}.{{alias}} modify column  {{column}} set masking policy  {{masking_policy_db}}.{{masking_policy_schema}}.{{masking_policy_name}};
                        {% endset %}
                        {% do run_query(query) %}
                    {% endif %}
                {% endfor %}

               {% endif %}
        {% endfor %}
    
    {% elif operation_type == "unapply" %}

        {% for node in graph.nodes.values() -%}

            {% set database = node.database | string %}
            {% set schema   = node.schema | string %}
            {% set node_unique_id = node.unique_id | string %}
            {% set node_resource_type = node.resource_type | string %}
            {% set materialization = node.config.materialized | string %}
            {% if materialization == "incremental" %}
                {% set materialization = "table" %}
            {% endif %}
            {% set alias    = node.alias %}

            {% set meta_columns = dbt_snow_mask.get_meta_objects(node_unique_id,meta_key,node_resource_type) %}

            {%- for meta_tuple in meta_columns if meta_columns | length > 0 %}
                {% set column   = meta_tuple[0] %}
                {% set masking_policy_name  = meta_tuple[1] %}

                {% if masking_policy_name is not none %}
                    {{ log(modules.datetime.datetime.now().strftime("%H:%M:%S") ~ " | " ~ operation_type ~ "ing masking policy to model  : " ~ database|upper ~ '.' ~ schema|upper ~ '.' ~ masking_policy_name|upper ~ " on " ~ database ~ '.' ~ schema ~ '.' ~ alias ~ '.' ~ column, info=True) }}
                    {% set query %}
                        alter {{materialization}}  {{database}}.{{schema}}.{{alias}} modify column  {{column}} unset masking policy
                    {% endset %}
                    {% do run_query(query) %}
                {% endif %}
            
            {% endfor %}

        {% endfor %}

    {% endif %}

{% endmacro %}