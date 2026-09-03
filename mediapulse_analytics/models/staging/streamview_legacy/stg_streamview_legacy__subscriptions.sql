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
        coalesce(
            try_to_timestamp_ntz(
                start_dt || ' ' || coalesce(nullif(start_tm, ''), '00:00:00'),
                'YYYY-MM-DD HH24:MI:SS'
            ),
            try_to_timestamp_ntz(
                start_dt || ' ' || coalesce(nullif(start_tm, ''), '00:00:00'),
                'YYYY-DD-MM HH24:MI:SS'
            )
        ) as subscription_started_at,
        end_dt,
        end_tm

    from source

)

select * from renamed
