{% macro create_masking_policy_mp_mask_timestamp(node_database, node_schema) %}
  {% set yaml_metadata %}
    masking_policy_name: mp_mask_timestamp
    masking_policy_params: "val timestamp_ntz"
    masking_policy_return: "timestamp_ntz"
    masking_policy_body: |
      case 
        when current_role() in ('SYSADMIN') then val 
        else '1900-01-01'::timestamp_ntz
      end
  {% endset %}

  {% set metadata_dict = fromyaml(yaml_metadata) %}

  {{ dbt_snow_mask.create_alter_masking_policy(node_database=node_database,
                                               node_schema=node_schema, 
                                               masking_policy_name=metadata_dict['masking_policy_name'], 
                                               masking_policy_params=metadata_dict['masking_policy_params'], 
                                               masking_policy_return=metadata_dict['masking_policy_return'],
                                               masking_policy_body=metadata_dict['masking_policy_body']) }}
{% endmacro %}