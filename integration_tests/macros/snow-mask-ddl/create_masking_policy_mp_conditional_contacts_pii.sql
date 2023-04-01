{% macro create_masking_policy_mp_conditional_contacts_pii(node_database, node_schema, masked_column) %}

    CREATE MASKING POLICY IF NOT EXISTS {{node_database}}.{{node_schema}}.mp_conditional_contacts_pii AS (
        {{masked_column}} string,
        last_name string
    ) RETURNS string ->
        CASE
            WHEN CURRENT_ROLE() IN ('ANALYST') THEN {{masked_column}}
            WHEN CURRENT_ROLE() IN ('DEVELOPER') AND last_name like 'A%' THEN {{masked_column}}
            WHEN CURRENT_ROLE() IN ('DEVELOPER') AND last_name like 'B%' THEN SHA2({{masked_column}})
            WHEN CURRENT_ROLE() IN ('DEVELOPER') AND last_name='Skeffington' THEN '*TARGETED_MASKING*'
             WHEN CURRENT_ROLE() IN ('SYSADMIN') THEN SHA2({{masked_column}})
        ELSE '**********'
        END

{% endmacro %}
