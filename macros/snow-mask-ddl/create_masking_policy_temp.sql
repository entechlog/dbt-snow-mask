{% macro create_masking_policy_temp(node_database,node_schema) %}

CREATE OR REPLACE MASKING POLICY {{node_database}}.{{node_schema}}.temp AS (val string) 
    RETURNS string ->
        CASE WHEN CURRENT_ROLE() IN ('ANALYST') THEN val 
             WHEN CURRENT_ROLE() IN ('SYSADMIN') THEN SHA2(val)
        ELSE '**********'
        END

{% endmacro %}