{% macro apply_masking_policy(resource_type="models",resource_name="undefined",meta_key="masking_policy") %}

    {% if execute %}

        {% if resource_type == "sources" and  resource_name == "undefined" %}
            {{ dbt_snow_mask.apply_masking_policy_list_for_sources(meta_key) }}
        {% elif resource_type|lower in ["models", "snapshots"] and resource_name == "undefined" %}
            {{ dbt_snow_mask.apply_masking_policy_list_for_models(meta_key) }}
        {% elif resource_type == "sources" and  resource_name != "undefined" %}
            {{ dbt_snow_mask.apply_masking_policy_list_for_onesource(meta_key,resource_name) }}
        {% elif resource_type|lower in ["models", "snapshots"] and resource_name != "undefined" %}
            {{ dbt_snow_mask.apply_masking_policy_list_for_onemodel(meta_key,resource_name) }}            
        {% endif %}

    {% endif %}

{% endmacro %}