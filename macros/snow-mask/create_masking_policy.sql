{% macro create_masking_policy(resource_type="sources",meta_key="masking_policy") %}

{% if execute %}

    {% set masking_policies = [] %}

    {% if resource_type == "sources" %}
        {% set masking_policies = get_masking_policy_list_for_sources(meta_key) %}
    {% else %}
        {% set masking_policies = get_masking_policy_list_for_models(meta_key) %}
    {% endif %}

    {{ log(modules.datetime.time() ~ " | macro - masking_policies           : " ~ masking_policies , info=True) }}

    {% for masking_policy in masking_policies | unique -%}
        {% set current_database = masking_policy[0] | string  %}
        {% set current_schema = masking_policy[1] | string  %}
        {% set current_policy_name = masking_policy[2] | string  %}
        {% set call_masking_policy_macro = context["create_masking_policy_" | string ~ current_policy_name | string]  %}
        {{ run_query(call_masking_policy_macro(current_database, current_schema)) }}
    {% endfor %}

{% endif %}

{% endmacro %}