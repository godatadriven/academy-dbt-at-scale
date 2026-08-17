with 

source as (

    select * from {{ source('podcasts', 'listens') }}

),

renamed as (

    select
        listen_id,
        episode_id,
        user_id,
        listened_at,
        listen_duration_seconds,
        platform

    from source

)

select * from renamed