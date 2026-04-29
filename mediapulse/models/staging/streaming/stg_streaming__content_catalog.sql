with 

source as (

    select * from {{ source('streaming', 'content_catalog') }}

),

renamed as (

    select
        content_id,
        title,
        {{ clean_string('genre') }} as genre,
        {{ clean_string('ctnt_type') }} as content_type,
        release_date,
        runtime_minutes

    from source

)

select * from renamed