{{
    config(
        materialized='view'
    )
}}

SELECT * FROM {{ source('raw_sakila', 'customer') }}