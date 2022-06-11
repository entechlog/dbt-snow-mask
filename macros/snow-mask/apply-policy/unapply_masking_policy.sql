{% macro unapply_masking_policy(resource_type="models",meta_key="masking_policy",operation_type="unapply") %}

    {% if execute %}

        {% if resource_type == "sources" %}
            {{ dbt_snow_mask.apply_masking_policy_list_for_sources(meta_key,operation_type) }}
        {% elif resource_type == "models" %}
            {{ dbt_snow_mask.apply_masking_policy_list_for_models(meta_key,operation_type) }}
        {% endif %}

    {% endif %}

{% endmacro %}