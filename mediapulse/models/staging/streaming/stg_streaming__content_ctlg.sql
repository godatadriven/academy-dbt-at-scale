with source as (

    select * from {{ source('streaming', 'content_ctlg') }}

),

renamed as (

    select
        content_id,
        title,
        genre,
        ctnt_type,
        release_date,
        runtime_minutes

    from source

)

select * from renamed