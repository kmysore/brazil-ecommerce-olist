with orders as (

    select * from {{ ref('stg_orders') }}

),

-- Aggregate line items up to order grain
items_by_order as (

    select
        order_id,
        count(*)                       as item_count,
        count(distinct product_id)     as distinct_product_count,
        sum(price)                     as product_revenue,
        sum(freight_value)             as freight_total,
        sum(item_total)                as order_total
    from {{ ref('fct_order_items') }}
    group by 1

),

-- Aggregate payments up to order grain (multiple rows per order possible)
payments_by_order as (

    select
        order_id,
        count(*)                       as payment_count,
        sum(payment_value)             as total_paid,
        max(payment_installments)      as max_installments
    from {{ ref('stg_order_payments') }}
    group by 1

),

-- Aggregate reviews up to order grain (usually one, occasionally more)
reviews_by_order as (

    select
        order_id,
        count(*)                       as review_count,
        avg(review_score)              as avg_review_score
    from {{ ref('stg_order_reviews') }}
    group by 1

),

final as (

    select
        -- primary key (the grain — one row per order)
        orders.order_id,

        -- foreign keys
        orders.customer_id,

        -- order attributes
        orders.order_status,

        -- order timestamps
        orders.order_purchased_at,
        orders.order_approved_at,
        orders.order_delivered_to_carrier_at,
        orders.order_delivered_to_customer_at,
        orders.order_estimated_delivery_at,

        -- item-level rollups (will be null if order has no items — ~775 such orders)
        coalesce(items_by_order.item_count, 0)              as item_count,
        coalesce(items_by_order.distinct_product_count, 0)  as distinct_product_count,
        coalesce(items_by_order.product_revenue, 0)         as product_revenue,
        coalesce(items_by_order.freight_total, 0)           as freight_total,
        coalesce(items_by_order.order_total, 0)             as order_total,

        -- payment-level rollups
        payments_by_order.payment_count,
        payments_by_order.total_paid,
        payments_by_order.max_installments,

        -- review-level rollups
        reviews_by_order.review_count,
        reviews_by_order.avg_review_score,

        -- derived measures
        datediff(
            'day',
            orders.order_purchased_at,
            orders.order_delivered_to_customer_at
        ) as days_to_deliver,

        -- governance flags (let the metric layer filter cleanly)
        (orders.order_delivered_to_customer_at is not null) as is_delivered,
        (orders.order_status = 'canceled')                  as is_canceled

    from orders
    left join items_by_order    on orders.order_id = items_by_order.order_id
    left join payments_by_order on orders.order_id = payments_by_order.order_id
    left join reviews_by_order  on orders.order_id = reviews_by_order.order_id

)

select * from final