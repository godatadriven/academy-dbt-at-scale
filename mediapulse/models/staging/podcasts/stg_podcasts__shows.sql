with source as (

    select * from {{ source('podcasts', 'shows') }}

),

renamed as (

    select
        show_id,
        show_name,
        host_name,
        category,
        cast(launched_at as timestamp)    as launched_at

    from source

)

select * from renamed
