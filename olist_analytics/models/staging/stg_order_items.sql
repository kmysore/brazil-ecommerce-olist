WITH source AS (

    SELECT * FROM {{ source('olist', 'raw_order_items') }}

),

renamed AS (

    SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        cast(price as number(10, 2)) as price,
        cast(freight_value as number(10, 2)) as freight_value,
        cast(shipping_limit_date as timestamp) as shipping_limit_date
    FROM source

)

SELECT * FROM renamed