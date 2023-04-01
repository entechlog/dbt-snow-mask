{% macro create_masking_policy_mp_conditional_customer_pii(node_database, node_schema, masked_column) %}

    CREATE MASKING POLICY IF NOT EXISTS {{node_database}}.{{node_schema}}.mp_conditional_customer_pii AS (
        {{masked_column}} string,
        store_id int,
        active int
    ) RETURNS string ->
        CASE
            WHEN CURRENT_ROLE() IN ('ANALYST') AND active=1 AND store_id=1 THEN {{masked_column}}
            WHEN CURRENT_ROLE() IN ('ANALYST') AND active=1 AND store_id=2 THEN SHA2({{masked_column}}) 
            WHEN CURRENT_ROLE() IN ('ANALYST') AND active=0 THEN '**********'
            WHEN CURRENT_ROLE() IN ('SYSADMIN') THEN SHA2({{masked_column}})
        ELSE '**********'
        END

{% endmacro %}
