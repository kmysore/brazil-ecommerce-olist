with order_items as (

    select * from {{ ref('stg_order_items') }}

),

final as (

    select
        -- composite key (the grain)
        order_id,
        order_item_id,

        -- foreign keys to dimensions
        product_id,
        seller_id,

        -- measures
        price,
        freight_value,
        price + freight_value as item_total,

        -- attribute
        shipping_limit_date

    from order_items

)

select * from final