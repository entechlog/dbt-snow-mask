{{ config(post_hook = "{{ dbt_snow_mask.apply_masking_policy('models') }}") }}

WITH contacts AS (
    SELECT
        contact_id,
        first_name,
        last_name,
        email,
        gender,
        ip_address,
        ssn,phone

    FROM {{ ref('contact') }}
),

final AS (
    SELECT *
    FROM contacts
)

SELECT * FROM final