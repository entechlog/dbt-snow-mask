{% macro create_masking_policy_mp_ip(node_database,node_schema) %}

CREATE MASKING POLICY IF NOT EXISTS {{node_database}}.{{node_schema}}.mp_ip AS (val string) 
  RETURNS string ->
      CASE WHEN CURRENT_ROLE() IN ('SYSADMIN') THEN val 
           WHEN CURRENT_ROLE() IN ('DEVELOPER') THEN SPLIT(val,'.')[3]::VARCHAR
      ELSE '**********'
      END

{% endmacro %}