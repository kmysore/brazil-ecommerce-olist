WITH source AS (

    SELECT * FROM {{ source('olist', 'raw_order_reviews') }}

),

renamed AS (

    SELECT
        review_id,
        order_id,
        cast(review_score as int) as review_score,
        review_comment_title,
        review_comment_message,
        cast(review_creation_date as timestamp) as review_created_at,
        cast(review_answer_timestamp as timestamp) as review_answered_at
    FROM source

)

SELECT * FROM renamed
