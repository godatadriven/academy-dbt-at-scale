-- dim_sales_reps: one row per AdConnect sales rep, with advertiser coverage stats.

with reps as (

    select * from {{ ref('stg_crm__sales_reps') }}

),

advertisers as (

    select
        sales_rep_id,
        count(*)    as total_advertisers

    from {{ ref('stg_crm__advertiser_accounts') }}
    group by sales_rep_id

)

select
    reps.rep_id,
    reps.rep_name,
    reps.region,
    reps.hire_date,
    coalesce(advertisers.total_advertisers, 0)    as total_advertisers

from reps
left join advertisers
    on reps.rep_id = advertisers.sales_rep_id
