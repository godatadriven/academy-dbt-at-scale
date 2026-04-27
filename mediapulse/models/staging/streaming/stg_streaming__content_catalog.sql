with 

source as (

    select * from {{ source('streaming', 'content_catalog') }}

),

renamed as (

    select
        content_id,
        title,
        lower(trim(genre)) as genre,
        lower(trim(ctnt_type)) as content_type,
        release_date,
        runtime_minutes

    from source

)

select * from renamed