{{ config(store_failures=true, limit=200) }}

select *
    from {{ ref('revenue_by_content') }}
    where mediapulse_revenue_dollars is null
