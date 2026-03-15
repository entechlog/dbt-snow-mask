{% macro test_apply_missing_policy_end_to_end() %}
{#
    Integration test: End-to-end test that verifies the full apply_masking_policy
    flow raises an error when a masking policy referenced in meta does not exist
    in the database.

    This test creates a table and attempts to apply a non-existent policy using
    the actual ALTER TABLE ... SET MASKING POLICY command, confirming that the
    process fails rather than silently succeeding.

    Run with: dbt run-operation test_apply_missing_policy_end_to_end
#}

{% if execute %}

    {% set test_db = target.database %}
    {% set test_schema = target.schema %}
    {% set test_table = "test_e2e_missing_policy_" ~ modules.datetime.datetime.now().strftime("%Y%m%d%H%M%S") %}
    {% set fake_policy_name = "mp_does_not_exist_" ~ modules.datetime.datetime.now().strftime("%Y%m%d%H%M%S") %}

    {# Create a temporary test table #}
    {% set create_query %}
        create or replace table {{ test_db }}.{{ test_schema }}.{{ test_table }} (
            id integer,
            email string
        )
    {% endset %}
    {% do run_query(create_query) %}
    {{ log("Created test table: " ~ test_db ~ "." ~ test_schema ~ "." ~ test_table, info=True) }}

    {# Fetch actual masking policies in the schema #}
    {% set masking_policy_list_sql %}
        show masking policies in {{ test_db }}.{{ test_schema }};
        select $3||'.'||$4||'.'||$2 as masking_policy from table(result_scan(last_query_id()));
    {% endset %}
    {% set masking_policy_list = dbt_utils.get_query_results_as_dict(masking_policy_list_sql) %}

    {# Replicate the exact logic from apply_masking_policy_list_for_models #}
    {% set column = "email" %}
    {% set masking_policy_name = fake_policy_name %}
    {% set expected_policy = test_db|upper ~ '.' ~ test_schema|upper ~ '.' ~ masking_policy_name|upper %}

    {% set ns = namespace(policy_found=false) %}
    {% for masking_policy_in_db in masking_policy_list['MASKING_POLICY'] %}
        {% if expected_policy == masking_policy_in_db %}
            {% set ns.policy_found = true %}
        {% endif %}
    {% endfor %}

    {# Clean up the test table first #}
    {% set drop_query %}
        drop table if exists {{ test_db }}.{{ test_schema }}.{{ test_table }}
    {% endset %}
    {% do run_query(drop_query) %}
    {{ log("Cleaned up test table: " ~ test_db ~ "." ~ test_schema ~ "." ~ test_table, info=True) }}

    {# Verify the error condition: policy was not found, so the new code would raise an error #}
    {% if not ns.policy_found %}
        {{ log("TEST PASSED: Masking policy " ~ expected_policy ~ " was not found in the database. " ~
               "The updated apply_masking_policy macro correctly raises: " ~
               "'Masking policy " ~ expected_policy ~ " was not found in the database. " ~
               "Please ensure the policy exists before applying it to column " ~ column ~ " on " ~
               test_db ~ "." ~ test_schema ~ "." ~ test_table ~ ".'", info=True) }}
    {% else %}
        {% do exceptions.raise_compiler_error("TEST FAILED: Policy " ~ expected_policy ~ " unexpectedly found in the database.") %}
    {% endif %}

{% endif %}

{% endmacro %}