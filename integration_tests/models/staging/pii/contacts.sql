WITH contacts AS (
    SELECT
        contact_id,
        first_name,
        last_name,
        email,
        gender,
        ip_address,
        ssn,phone

    FROM {{ ref('hipaa_contact') }}
),

final AS (
    SELECT *
    FROM contacts
)

SELECT * FROM final