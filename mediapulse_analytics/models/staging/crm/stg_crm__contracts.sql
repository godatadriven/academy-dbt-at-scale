with source as (

    select * from {{ source('crm', 'contracts') }}

),

renamed as (

    select
        contract_id,
        advertiser_id,
        contract_value_cents,
        cast(start_date as date)    as start_date,
        cast(end_date as date)      as end_date,
        renewal_status

    from source

)

select * from renamed
