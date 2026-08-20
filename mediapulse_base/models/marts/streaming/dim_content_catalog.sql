-- dim_content_catalog: one row per streaming catalog item.

with content as (

    select * from {{ ref('stg_streaming__content_ctlg') }}

)

select
    content_id,
    title,
    genre,
    ctnt_type                     as content_type,
    cast(release_date as date)    as release_date,
    runtime_minutes

from content
