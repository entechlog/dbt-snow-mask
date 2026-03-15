{% macro test_existing_masking_policy_is_found() %}
{#
    Integration test: Verifies that a masking policy that exists in the database
    is correctly found during the apply process and does not trigger an error.

    This test creates a masking policy, then verifies the lookup logic finds it.

    Run with: dbt run-operation test_existing_masking_policy_is_found
#}

{% if execute %}

    {% set test_db = target.database %}
    {% set test_schema = target.schema %}
    {% set test_policy_name = "mp_test_existing_" ~ modules.datetime.datetime.now().strftime("%Y%m%d%H%M%S") %}

    {# Create a test masking policy #}
    {% set create_policy_query %}
        create masking policy if not exists {{ test_db }}.{{ test_schema }}.{{ test_policy_name }} as (val string)
        returns string ->
            case
                when current_role() in ('SYSADMIN') then val
                else '***MASKED***'
            end
    {% endset %}
    {% do run_query(create_policy_query) %}
    {{ log("Created test masking policy: " ~ test_db ~ "." ~ test_schema ~ "." ~ test_policy_name, info=True) }}

    {# Fetch masking policies in the schema #}
    {% set masking_policy_list_sql %}
        show masking policies in {{ test_db }}.{{ test_schema }};
        select $3||'.'||$4||'.'||$2 as masking_policy from table(result_scan(last_query_id()));
    {% endset %}
    {% set masking_policy_list = dbt_utils.get_query_results_as_dict(masking_policy_list_sql) %}

    {# Simulate the policy lookup logic #}
    {% set expected_policy = test_db|upper ~ '.' ~ test_schema|upper ~ '.' ~ test_policy_name|upper %}
    {% set ns = namespace(policy_found=false) %}
    {% for masking_policy_in_db in masking_policy_list['MASKING_POLICY'] %}
        {% if expected_policy == masking_policy_in_db %}
            {% set ns.policy_found = true %}
        {% endif %}
    {% endfor %}

    {# Clean up the test masking policy #}
    {% set drop_policy_query %}
        drop masking policy if exists {{ test_db }}.{{ test_schema }}.{{ test_policy_name }}
    {% endset %}
    {% do run_query(drop_policy_query) %}
    {{ log("Cleaned up test masking policy: " ~ test_db ~ "." ~ test_schema ~ "." ~ test_policy_name, info=True) }}

    {# Assert that the policy WAS found #}
    {% if ns.policy_found %}
        {{ log("TEST PASSED: Existing masking policy " ~ expected_policy ~ " was correctly found. The apply macro would proceed normally.", info=True) }}
    {% else %}
        {% do exceptions.raise_compiler_error("TEST FAILED: Policy " ~ expected_policy ~ " should have been found in the database, but it was not.") %}
    {% endif %}

{% endif %}

{% endmacro %}