with orders as (

    select * from {{ ref('fct_orders') }}

),

monthly as (

    select
        date_trunc('month', order_purchased_at) as purchase_month,

        -- bookings: commitments (exclude canceled)
        sum(case when not is_canceled then product_revenue end) as bookings,
        count(case when not is_canceled then 1 end)             as booking_count,

        -- revenue: realized (delivered only)
        sum(case when is_delivered then product_revenue end)    as revenue,
        count(case when is_delivered then 1 end)                as delivered_order_count,

        -- supplementary
        sum(case when is_delivered then freight_total end)      as freight_revenue,
        sum(case when is_delivered then order_total end)        as total_transaction_value,
        count(*)                                                 as total_order_count,
        count(case when is_canceled then 1 end)                 as canceled_order_count,

        avg(case when is_delivered then days_to_deliver end)    as avg_days_to_deliver

    from orders
    where order_purchased_at is not null
    group by 1

)

select * from monthly
order by purchase_month