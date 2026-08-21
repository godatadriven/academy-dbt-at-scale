with source as (

    select * from {{ source('streamview_legacy', 'acct_subs_archive') }}

),

renamed as (

    select
        subscriber_ref    as legacy_subscriber_id,
        tier,
        account_status,
        start_dt,
        start_tm,
        end_dt,
        end_tm

    from source

)

select * from renamed
