-- dim_advertisers: one row per advertiser account, enriched with the owning
-- sales rep. advertiser_id matches the advertiser_id used in the ads domain's
-- campaigns, so this can be joined to spend/revenue marts on that column.

with advertisers as (

    select * from {{ ref('stg_crm__advertiser_accounts') }}

),

reps as (

    select
        rep_id,
        rep_name

    from {{ ref('stg_crm__sales_reps') }}

)

select
    advertisers.advertiser_id,
    advertisers.advertiser_name,
    advertisers.industry,
    advertisers.contract_tier,
    advertisers.account_status,
    advertisers.signed_at,
    reps.rep_id,
    reps.rep_name

from advertisers
left join reps
    on advertisers.sales_rep_id = reps.rep_id
