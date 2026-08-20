with source as (

    select * from {{ source('news', 'authors') }}

),

renamed as (

    select
        author_id,
        name                            as author_name,
        email,
        cast(joined_at as timestamp)    as joined_at

    from source

)

select * from renamed
