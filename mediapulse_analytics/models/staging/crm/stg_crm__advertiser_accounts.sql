with source as (

    select * from {{ source('crm', 'advertiser_accounts') }}

),

renamed as (

    select
        advertiser_id,
        lower(advertiser_name),
        lower(industry),
        sales_rep_id,
        lower(contract_tier),
        lower(account_status),
        cast(signed_at as date)    as signed_at

    from source

)

select * from renamed
