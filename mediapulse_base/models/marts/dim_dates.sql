-- dim_dates: shared calendar dimension.
-- Every fact table in either project can join to this on its date column to get
-- calendar attributes (year, quarter, month, day of week) without repeating the
-- date-part logic in every mart.

with spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2023-01-01' as date)",
        end_date="cast('2026-12-31' as date)"
    ) }}

),

final as (

    select
        cast(date_day as date)                    as date_day,
        extract(year from date_day)                as year,
        extract(quarter from date_day)              as quarter,
        extract(month from date_day)                as month,
        extract(day from date_day)                   as day_of_month,
        extract(dayofweek from date_day)             as day_of_week,
        date_trunc('month', date_day)                as month_start_date,
        case
            when extract(dayofweek from date_day) in (0, 6) then true
            else false
        end                                          as is_weekend

    from spine

)

select * from final
