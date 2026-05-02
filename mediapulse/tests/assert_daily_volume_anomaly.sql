{{ config(
    store_failures = true,
    severity = 'warn'
) }}

with daily_counts as (
    select
        impression_date,
        count(*) as row_count
    from {{ ref('revenue_by_content') }}
    group by 1
),
averages as (
    select
        row_count as yesterday_vol,
        avg(row_count) over (
            order by impression_date 
            rows between 7 preceding and 1 preceding
        ) as avg_7day_vol
    from daily_counts
)
select *
from averages
where yesterday_vol < (avg_7day_vol * 0.8)
   or yesterday_vol > (avg_7day_vol * 1.2)