{% macro apply_masking_policy_list_for_sources(meta_key,operation_type="apply") %}

    {% for node in graph.sources.values() -%}

        {% set database = node.database | string %}
        {% set schema   = node.schema | string %}
        {% set name   = node.name | string %}
        {% set identifier = (node.identifier | default(name, True)) | string %}

        {% set unique_id = node.unique_id | string %}
        {% set resource_type = node.resource_type | string %}
        {% set materialization = "table" %}

        {% set relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) %}
        {% if relation.is_view %}
          {% set materialization = "view" %}
        {% endif %}

        {% set meta_columns = dbt_snow_mask.get_meta_objects(unique_id,meta_key,resource_type) %}

        {# Use the database and schema for the source node: #}
        {#     In the apple for models variant of this file it instead uses the model.database/schema metadata #}
        {% set masking_policy_db = node.database %}
        {% set masking_policy_schema = node.schema %}
		
        {# Override the database and schema name when use_common_masking_policy_db flag is set #}
        {# Override the schema name (in the current_database) when use_common_masking_policy_schema flag is set #}
        {%- if (var('use_common_masking_policy_db', 'False')|upper in ['TRUE','YES']) or (var('use_common_masking_policy_schema', 'False')|upper in ['TRUE','YES']) -%}
            {% if var('common_masking_policy_schema') %}
                {% set masking_policy_schema = var('common_masking_policy_schema') | string  %}

                {%- if (var('use_common_masking_policy_db', 'False')|upper in ['TRUE','YES']) and (var('use_common_masking_policy_schema', 'False')|upper in ['FALSE','NO']) -%}
                    {% if var('common_masking_policy_db') %}
                        {% set masking_policy_db = var('common_masking_policy_db') | string  %}
                    {% endif %}
                {% endif %}
                
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
                        {{ log(modules.datetime.datetime.now().strftime("%H:%M:%S") ~ " | " ~ operation_type ~ "ing masking policy to source : " ~ masking_policy_db|upper ~ '.' ~ masking_policy_schema|upper ~ '.' ~ masking_policy_name|upper ~ " on " ~ database ~ '.' ~ schema ~ '.' ~ identifier ~ '.' ~ column, info=True) }}
                        {% set query %}
                            {% if operation_type == "apply" %}
                                alter {{materialization}}  {{database}}.{{schema}}.{{identifier}} modify column  {{column}} set masking policy  {{masking_policy_db}}.{{masking_policy_schema}}.{{masking_policy_name}}
                            {% elif operation_type == "unapply" %}
                                alter {{materialization}}  {{database}}.{{schema}}.{{identifier}} modify column  {{column}} unset masking policy
                            {% endif %}
                        {% endset %}
                        {% do run_query(query) %}
                    {% endif %}
                {% endfor %}
            {% endif %}

        {% endfor %}

    {% endfor %}

{% endmacro %}