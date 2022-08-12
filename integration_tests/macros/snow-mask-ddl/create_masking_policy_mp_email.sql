{% macro create_masking_policy_mp_email(node_database,node_schema) %}

CREATE MASKING POLICY IF NOT EXISTS {{node_database}}.{{node_schema}}.mp_email AS (val string) 
  RETURNS string ->
      CASE WHEN CURRENT_ROLE() IN ('SYSADMIN') THEN val 
           WHEN CURRENT_ROLE() IN ('DEVELOPER') THEN SHA2(val)
      ELSE '**********'
      END

{% endmacro %}