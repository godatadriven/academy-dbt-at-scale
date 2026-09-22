-- fct_podcast_listens: one row per podcast listen session.
-- to do: put model in yaml file
with listens as (select * from {{ ref("int_podcasts_listens_completion_rates") }})

, episodes as (select * from {{ ref('stg_podcasts__episodes') }})

select
    episode_id,
    show_id,
    platform,
    count(listen_id) as number_of_listens,  -- will never be 0 atm
    avg(listen_duration_seconds) as average_listen_seconds,
    avg(completion_rate) as average_completion_rate,
    case 
        when average_completion_rate = 0 then 'no_listens'
        when average_completion_rate > .90 then 'completed'
        when average_completion_rate < .10 then 'dropped_before_content'
        else 'partial'
    end as completion_bucket
from listens
group by all

union all

select
    episode_id,
    show_id,
    null as platform,
    0 as number_of_listens,
    null as average_listen_seconds,
    null as average_completion_rate,
    'no listens' as completion_bucket
from 
    episodes
where
    episode_id not in (select distinct episode_id from listens)


