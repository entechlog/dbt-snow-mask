{% macro unapply_masking_policy(resource_type="models",resource_name="undefined",meta_key="masking_policy",operation_type="unapply") %}

    {% if execute %}

        {% if resource_type == "sources" and  resource_name == "undefined" %}
            {{ dbt_snow_mask.apply_masking_policy_list_for_sources(meta_key,operation_type) }}
        {% elif resource_type|lower in ["models", "snapshots"] and resource_name == "undefined" %}
            {{ dbt_snow_mask.apply_masking_policy_list_for_models(meta_key,operation_type) }}
        {% elif resource_type == "sources" and  resource_name != "undefined" %}
            {{ dbt_snow_mask.apply_masking_policy_list_for_onesource(meta_key,resource_name,operation_type) }}
        {% elif resource_type|lower in ["models", "snapshots"] and resource_name != "undefined" %}
            {{ dbt_snow_mask.apply_masking_policy_list_for_onemodel(meta_key,resource_name,operation_type) }}            
        {% endif %}

    {% endif %}

{% endmacro %}