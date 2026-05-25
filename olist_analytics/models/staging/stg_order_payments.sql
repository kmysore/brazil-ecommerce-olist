WITH source AS (

    SELECT * FROM {{ source('olist', 'raw_order_payments') }}

),

renamed AS (

    SELECT
        order_id,
        payment_type,
        cast(payment_sequential as int) as payment_sequential,
        cast(payment_installments as int) as payment_installments,
        cast(payment_value as number(10, 2)) as payment_value
    FROM source

)

SELECT * FROM renamed