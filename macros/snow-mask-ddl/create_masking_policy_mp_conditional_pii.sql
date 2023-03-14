{% macro create_masking_policy_mp_conditional_pii(node_database, node_schema, masked_column) %}

    CREATE MASKING POLICY IF NOT EXISTS {{node_database}}.{{node_schema}}.mp_conditional_pii AS (
        {{masked_column}} string,
        my_conditional_col_1 string,
        my_conditional_col_2 string
    ) RETURNS string ->
        CASE 
            WHEN CURRENT_ROLE() IN ('ANALYST') AND my_conditional_col_1='foo' THEN {{masked_column}}
            WHEN CURRENT_ROLE() IN ('ANALYST') AND my_conditional_col_2='bar' THEN SHA2({{masked_column}})
             WHEN CURRENT_ROLE() IN ('SYSADMIN') THEN SHA2({{masked_column}})
        ELSE '**********'
        END

{% endmacro %}
