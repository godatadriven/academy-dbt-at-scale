-- fct_advertiser_contracts: one row per advertiser contract term.

with contracts as (

    select * from {{ ref('stg_crm__contracts') }}

)

select
    contract_id,
    advertiser_id,
    contract_value_cents / 100.0                as contract_value_dollars,
    start_date,
    end_date,
    datediff('day', start_date, end_date)    as contract_length_days,
    renewal_status

from contracts
