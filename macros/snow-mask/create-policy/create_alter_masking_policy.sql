{% macro create_alter_masking_policy(node_database, 
                                     node_schema, 
                                     masking_policy_name, 
                                     masking_policy_params, 
                                     masking_policy_return, 
                                     masking_policy_body, 
                                     masking_policy_type="masking") %}

  {%- set masking_policy_relation = node_database ~ "." ~ node_schema ~ "." ~ masking_policy_name -%}
  {%- set upper_masking_policy_name = masking_policy_name | upper -%}

  {%- if execute -%}
    {%- set lookup_query -%}
      show {{ masking_policy_type }} policies like '{{ upper_masking_policy_name }}' in schema {{ node_schema }}
    {%- endset -%}
    {%- set policy_list = run_query(lookup_query) -%}

    {%- if policy_list.columns["name"].values() | count > 0 -%}
      alter {{ masking_policy_type }}  policy {{ masking_policy_relation }} set body
    {%- else -%}
      create {{ masking_policy_type }} policy if not exists {{ masking_policy_relation }} as (
        
      {%- if masking_policy_params is not string and masking_policy_params is iterable -%}
        {%- for parameter in masking_policy_params -%}
          {{ parameter }}{{ ", " if not loop.last }}
        {%- endfor -%}
      {%- else -%}
        {{ masking_policy_params }}
      {%- endif -%}
        ) returns {{ masking_policy_return }} 
    {%- endif -%}

    {{ "->\n" }}

    {%- if masking_policy_body is not string and masking_policy_body is iterable -%}  
      {%- for code_line in masking_policy_body -%}
        {{ code_line }} {{ "\n" if not loop.last }}
      {%- endfor -%}
    {%- else -%}
      {{ masking_policy_body }}
    {%- endif -%}
  {%- endif -%}
{% endmacro %}