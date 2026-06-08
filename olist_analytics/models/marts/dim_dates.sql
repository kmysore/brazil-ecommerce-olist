with date_spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2016-01-01' as date)",
        end_date="cast('2019-12-31' as date)"
    ) }}

),

final as (

    select
        cast(date_day as date)                                  as date_day,

        -- year / quarter / month parts
        extract(year from date_day)                             as year_number,
        extract(quarter from date_day)                          as quarter_number,
        extract(month from date_day)                            as month_number,
        extract(day from date_day)                              as day_of_month,
        extract(dayofweek from date_day)                        as day_of_week_number,

        -- pre-truncated periods (handy for joins / grouping)
        date_trunc('week', date_day)::date                      as week_start,
        date_trunc('month', date_day)::date                     as month_start,
        date_trunc('quarter', date_day)::date                   as quarter_start,
        date_trunc('year', date_day)::date                      as year_start,

        -- human-friendly labels
        to_char(date_day, 'YYYY-MM')                            as year_month,
        extract(year from date_day) || '-Q' || extract(quarter from date_day) as year_quarter,
        to_char(date_day, 'Mon')                                as month_name,
        to_char(date_day, 'Dy')                                 as day_name,

        -- useful booleans
        (extract(dayofweek from date_day) in (0, 6))            as is_weekend,
        (date_day = last_day(date_day, 'month'))                as is_month_end,
        (date_day = last_day(date_day, 'quarter'))              as is_quarter_end,
        (date_day = last_day(date_day, 'year'))                 as is_year_end

    from date_spine

)

select * from final