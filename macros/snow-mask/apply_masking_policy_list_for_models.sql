{% macro apply_masking_policy_list_for_models(meta_key) %}

        {% set model_id = model.unique_id | string %}
        {% set alias    = model.alias %}    
        {% set database = model.database %}
        {% set schema   = model.schema %}
        {% set materialization = model.config.get("materialized") %}
        {% if materialization == "incremental" %}
            {% set materialization = "table" %}
        {% endif %}
        {% set meta_columns = dbt_snow_mask.get_meta_objects(model_id,meta_key) %}

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
                        {{ log(modules.datetime.time() ~ " | applying masking policy (model)   : " ~ database|upper ~ '.' ~ schema|upper ~ '.' ~ masking_policy_name|upper ~ " on " ~ database ~ '.' ~ schema ~ '.' ~ alias ~ '.' ~ column, info=True) }}
                        {% set query %}
                        alter {{materialization}}  {{database}}.{{schema}}.{{alias}} modify column  {{column}} set masking policy  {{database}}.{{schema}}.{{masking_policy_name}};
                        {% endset %}
                        {% do run_query(query) %}
                    {% endif %}
                {% endfor %}

               {% endif %}
        {% endfor %}
    
    {% endmacro %}