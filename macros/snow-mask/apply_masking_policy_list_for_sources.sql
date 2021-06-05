{% macro apply_masking_policy_list_for_sources(meta_key) %}

    {% for node in graph.sources.values() -%}
        
        {% set database = node.database | string %}
        {% set schema   = node.schema | string %}
        {% set name   = node.name | string %}
        {% set unique_id = node.unique_id | string %}
        {% set resource_type = node.resource_type | string %}
        {% set materialization = "table" %}

        {% set meta_columns = dbt_snow_mask.get_meta_objects(unique_id,meta_key,resource_type) %}

        {% set masking_policy_list_sql %}     
            show masking policies in {{database}}.{{schema}};
            select $3||'.'||$4||'.'||$2 as masking_policy from table(result_scan(last_query_id()));
        {% endset %}

        {%- for meta_tuple in meta_columns if meta_columns | length > 0 %}
            {% set column   = meta_tuple[0] %}
            {% set masking_policy_name  = meta_tuple[1] %}
            
            {% if masking_policy_name is not none %}
                {% set masking_policy_list = dbt_utils.get_query_results_as_dict(masking_policy_list_sql) %}

                {% for masking_policy_in_db in masking_policy_list['MASKING_POLICY'] %}
                    {% if database|upper ~ '.' ~ schema|upper ~ '.' ~ masking_policy_name|upper == masking_policy_in_db %}
                        {{ log(modules.datetime.time() ~ " | applying masking policy (source)  : " ~ database|upper ~ '.' ~ schema|upper ~ '.' ~ masking_policy_name|upper ~ " on " ~ database ~ '.' ~ schema ~ '.' ~ name ~ '.' ~ column, info=True) }}
                        {% set query %}
                        alter {{materialization}}  {{database}}.{{schema}}.{{name}} modify column  {{column}} set masking policy  {{database}}.{{schema}}.{{masking_policy_name}}
                        {% endset %}
                        {% do run_query(query) %}
                    {% endif %}
                {% endfor %}
            {% endif %}

        {% endfor %}
    
    {% endfor %}
    
{% endmacro %}