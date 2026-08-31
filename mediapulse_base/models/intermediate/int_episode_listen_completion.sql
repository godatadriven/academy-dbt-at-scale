with episodes as (

    select
        episode_id,
        show_id,
        cast(published_at as timestamp) as published_at,
        duration_seconds
    from {{ ref('stg_podcasts__episodes') }}

),

listens as (

    select
        episode_id,
        listen_duration_seconds
    from {{ ref('stg_podcasts__listens') }}

),

listen_stats as (

    select
        l.episode_id,
        count(*)                                                              as total_listen_sessions,
        avg(
            least(1.0 * l.listen_duration_seconds / nullif(e.duration_seconds, 0), 1.0)
        )                                                                     as avg_completion_rate,
        sum(l.listen_duration_seconds)                                        as total_listen_seconds
    from listens as l
    inner join episodes as e on l.episode_id = e.episode_id
    group by l.episode_id

),

final as (

    select
        e.episode_id,
        e.show_id,
        e.published_at,
        e.duration_seconds,
        coalesce(ls.total_listen_sessions, 0)                                as total_listen_sessions,
        ls.avg_completion_rate,
        ls.total_listen_seconds,
        case
            when ls.avg_completion_rate is null then 'no_listens'
            when ls.avg_completion_rate >= 0.75 then 'completed'
            when ls.avg_completion_rate >= 0.25 then 'partial'
            else                                     'dropped'
        end                                                                   as engagement_tier
    from episodes as e
    left join listen_stats as ls on e.episode_id = ls.episode_id

)

select * from final
