{% macro apply_masking_policy(resource_type="models",meta_key="masking_policy") %}

    {% if execute %}

        {% if resource_type == "sources" %}
            {{ dbt_snow_mask.apply_masking_policy_list_for_sources(meta_key) }}
        {% elif resource_type|lower in ["models", "snapshots"] %}
            {{ dbt_snow_mask.apply_masking_policy_list_for_models(meta_key) }}
        {% endif %}

    {% endif %}

{% endmacro %}