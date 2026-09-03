{{
    config(error_if = '>0')
}}

select
    subs.user_id
    , subs.plan_type
    , staff.user_id is not null as is_staff
    , subs.monthly_fee_cents
    , iff(
        is_staff
        , subs.monthly_fee_cents / 875 * 1000
        , subs.monthly_fee_cents
        ) as full_price
    , floor(full_price) as full_price_round
    , case
        when subs.plan_type = 'basic' and abs(full_price_round - 599) <= 1
        then true
        when subs.plan_type = 'standard' and abs(full_price_round - 999) <= 1
        then true
        when subs.plan_type = 'premium' and abs(full_price_round - 1499) <= 1
        then true
        else false
        end as check_bool
from {{ ref('stg_streaming__subscriptions_lifecycle_rec') }} subs
left join {{ ref('staff_members') }} staff on subs.user_id = staff.user_id
where check_bool = false
