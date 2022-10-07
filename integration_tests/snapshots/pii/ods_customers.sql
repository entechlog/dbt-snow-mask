{% snapshot ods_customers %}

{{
    config(
        target_schema='pii',
        strategy='timestamp',
        unique_key='customer_id',
        updated_at='last_update',
        invalidate_hard_deletes=true
    )
}}

SELECT
    customer_id,
    store_id,
    first_name,
    last_name,
    email,
    address_id,
    active,
    create_date,
    last_update
FROM {{ source('seeds', 'customer') }}


{% endsnapshot %}