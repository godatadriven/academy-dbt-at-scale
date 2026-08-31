with
    base as (
        select show_id, show_name, host_name, category, launched_at
        from {{ ref("stg_podcasts__shows") }}
    ),

    -- Step 1: normalize HTML entities and stray markup before whitespace cleanup
    decoded as (
        select
            show_id,
            replace(show_name, '&amp;', '&') as show_name,
            host_name,
            category,
            launched_at
        from base
    ),

    -- Step 2: collapse all whitespace variants (tabs, multiple spaces) into single
    -- spaces,
    -- then trim leading/trailing whitespace
    whitespace_fixed as (
        select
            show_id,
            trim(regexp_replace(show_name, '\\s+', ' ')) as show_name,
            trim(regexp_replace(host_name, '\\s+', ' ')) as host_name,
            category,
            launched_at
        from decoded
    ),

    -- Step 3: strip decorative / marketing noise from show_name
    -- (quotes, trademark symbols, trailing punctuation, "(Podcast)", "– Official",
    -- "#1", etc.)
    show_name_stripped as (
        select
            show_id,
            trim(
                regexp_replace(
                    show_name,
                    '["™]|\\s*\\(Podcast\\)|\\s*[–-]\\s*Official|\\s*#\\d+|[!?]+$|\\.\\.\\.$',
                    ''
                )
            ) as show_name,
            host_name,
            category,
            launched_at
        from whitespace_fixed
    ),

    -- Step 4: strip credential/role suffixes from host_name
    -- (PhD, Jr., (host), and re-collapse any double spaces left behind)
    host_name_stripped as (
        select
            show_id,
            show_name,
            trim(
                regexp_replace(
                    regexp_replace(
                        host_name, '\\s+(PhD|Jr\\.|\\(host\\))\\s*$', '', 1, 1, 'i'
                    ),
                    '\\s+',
                    ' '
                )
            ) as host_name,
            category,
            launched_at
        from show_name_stripped
    ),

    -- Step 5: normalize casing (title case) now that noise is gone
    final as (
        select
            show_id,
            initcap(show_name) as show_name,
            initcap(host_name) as host_name,
            category,
            launched_at
        from host_name_stripped
    )

select *
from final