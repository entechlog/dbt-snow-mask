{{
    config(
        materialized='view'
    )
}}

SELECT * FROM {{ source('seeds', 'customer') }}