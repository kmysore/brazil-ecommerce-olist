with source as (

    select * from {{ source('olist', 'raw_orders') }}

),

renamed as (

    select
        -- identifiers
        order_id,
        customer_id,

        -- status
        order_status,

        -- timestamps (cast from string)
        cast(order_purchase_timestamp as timestamp)      as order_purchased_at,
        cast(order_approved_at as timestamp)             as order_approved_at,
        cast(order_delivered_carrier_date as timestamp)  as order_delivered_to_carrier_at,
        cast(order_delivered_customer_date as timestamp) as order_delivered_to_customer_at,
        cast(order_estimated_delivery_date as timestamp) as order_estimated_delivery_at

    from source

)

select * from renamed