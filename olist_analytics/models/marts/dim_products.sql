with products as (

    select * from {{ ref('stg_products') }}

),

translation as (

    select * from {{ ref('raw_product_category_name_translation') }}

),

final as (

    select
        -- primary key
        products.product_id,

        -- category: English if available, else Portuguese, else 'unknown'
        coalesce(
            translation.product_category_name_english,
            products.product_category_name,
            'unknown'
        ) as product_category,

        -- keep the original Portuguese too, for traceability
        products.product_category_name as product_category_portuguese,

        -- physical attributes
        products.product_weight_g,
        products.product_length_cm,
        products.product_height_cm,
        products.product_width_cm

    from products
    left join translation
        on products.product_category_name = translation.product_category_name

)

select * from final