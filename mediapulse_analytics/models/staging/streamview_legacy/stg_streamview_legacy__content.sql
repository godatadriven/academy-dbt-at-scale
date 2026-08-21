with source as (

    select * from {{ source('streamview_legacy', 'media_catalog_archive') }}

),

renamed as (

    select
        media_id                   as legacy_content_id,
        media_title                as content_title,
        category,
        media_format                as content_format,
        cast(release_dt as date)    as release_date,
        duration_min                as duration_minutes

    from source

)

select * from renamed
