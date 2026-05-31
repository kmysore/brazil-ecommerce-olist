with sellers as (
    
    select * from {{ ref('stg_sellers')}}

), 

final as (
    SELECT
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    FROM sellers
)

select * from final

