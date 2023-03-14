{% macro create_masking_policy(resource_type="sources",meta_key="masking_policy") %}

{% if execute %}

    {% set masking_policies = [] %}

    {% if resource_type == "sources" %}
        {% set masking_policies = dbt_snow_mask.get_masking_policy_list_for_sources(meta_key) %}
    {% else %}
        {% set masking_policies = dbt_snow_mask.get_masking_policy_list_for_models(meta_key) %}
    {% endif %}

    {% for masking_policy in masking_policies | unique -%}

        {% set masking_policy_db = masking_policy[0] | string  %}
        {% set masking_policy_schema = masking_policy[1] | string  %}

        {# Override the database and schema name when use_common_masking_policy_db flag is set #}
        {%- if (var('use_common_masking_policy_db', 'False')|upper in ['TRUE','YES']) -%}
            {% if (var('common_masking_policy_db') and var('common_masking_policy_schema')) %}
                {% set masking_policy_db = var('common_masking_policy_db') | string  %}
                {% set masking_policy_schema = var('common_masking_policy_schema') | string  %}
            {% endif %}
        {% endif %}

        {# Override the schema name (in the masking_policy_db) when use_common_masking_policy_schema_only flag is set #}
        {%- if (var('use_common_masking_policy_schema_only', 'False')|upper in ['TRUE','YES']) and (var('use_common_masking_policy_db', 'False')|upper in ['FALSE','NO']) -%}
            {% if var('common_masking_policy_schema') %}
                {% set masking_policy_schema = var('common_masking_policy_schema') | string  %}
            {% endif %}
        {% endif %}

        {% set current_policy_name          = masking_policy[2] | string  %}
        {% set conditionally_masked_column  = masking_policy[3] %}

        {%- if (var('create_masking_policy_schema', 'True')|upper in ['TRUE','YES']) -%}
            {% do adapter.create_schema(api.Relation.create(database=masking_policy_db, schema=masking_policy_schema)) %}
        {% endif %}

        {% set call_masking_policy_macro = context["create_masking_policy_" | string ~ current_policy_name | string]  %}
        {% if conditionally_masked_column is not none %}
            {% set result = run_query(call_masking_policy_macro(masking_policy_db, masking_policy_schema, conditionally_masked_column)) %}
        {% else %}
            {% set result = run_query(call_masking_policy_macro(masking_policy_db, masking_policy_schema)) %}
        {% endif %}
    {% endfor %}

{% endif %}

{% endmacro %}
