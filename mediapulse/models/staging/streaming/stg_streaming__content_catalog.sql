with 

source as (

    select * from {{ source('streaming', 'content_catalog') }}

),

renamed as (

    select
        content_id,
        title,
        trim(lower(genre)) as genre,
        ctnt_type as content_type,
        release_date,
        runtime_minutes as runtime_in_minutes

    from source

)

select * from renamed