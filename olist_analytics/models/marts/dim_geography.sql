with geography as (

    select * from {{ ref('raw_geography') }}

),

final as (

    select
        state_code,
        state_name,
        region
    from geography

)

select * from final