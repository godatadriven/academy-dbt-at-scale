with source as (

    select * from {{ source('crm', 'touchpoints') }}

),

renamed as (

    select
        touchpoint_id,
        advertiser_id,
        rep_id,
        touchpoint_type,
        cast(occurred_at as timestamp)    as occurred_at,
        notes

    from source

)

select * from renamed
