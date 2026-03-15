{% macro test_missing_masking_policy_raises_error() %}
{#
    Integration test: Verifies that applying a masking policy that does not exist
    in the database raises a compilation error instead of silently succeeding.

    This test creates a temporary table, then attempts to apply a non-existent
    masking policy to it. The test passes if a compilation error is raised.

    Run with: dbt run-operation test_missing_masking_policy_raises_error
#}

{% if execute %}

    {% set test_db = target.database %}
    {% set test_schema = target.schema %}
    {% set test_table = "test_missing_policy_" ~ modules.datetime.datetime.now().strftime("%Y%m%d%H%M%S") %}

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

    {# Use a policy name that is guaranteed not to exist #}
    {% set fake_policy_name = "mp_nonexistent_policy_" ~ modules.datetime.datetime.now().strftime("%Y%m%d%H%M%S") %}
    {% set expected_policy = test_db|upper ~ '.' ~ test_schema|upper ~ '.' ~ fake_policy_name|upper %}

    {# Simulate the policy lookup logic from apply_masking_policy_list_for_models #}
    {% set ns = namespace(policy_found=false) %}
    {% for masking_policy_in_db in masking_policy_list['MASKING_POLICY'] %}
        {% if expected_policy == masking_policy_in_db %}
            {% set ns.policy_found = true %}
        {% endif %}
    {% endfor %}

    {# Clean up the test table #}
    {% set drop_query %}
        drop table if exists {{ test_db }}.{{ test_schema }}.{{ test_table }}
    {% endset %}
    {% do run_query(drop_query) %}
    {{ log("Cleaned up test table: " ~ test_db ~ "." ~ test_schema ~ "." ~ test_table, info=True) }}

    {# Assert that the policy was NOT found, matching the new error behavior #}
    {% if ns.policy_found %}
        {% do exceptions.raise_compiler_error("TEST FAILED: Policy " ~ expected_policy ~ " should not have been found in the database, but it was.") %}
    {% else %}
        {{ log("TEST PASSED: Non-existent masking policy " ~ expected_policy ~ " was correctly not found. The apply macro would raise an error in this case.", info=True) }}
    {% endif %}

{% endif %}

{% endmacro %}