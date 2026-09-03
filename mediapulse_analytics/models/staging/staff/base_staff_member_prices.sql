with staff as (

    select * from {{ ref('stg_staff__members') }}

),

streaming as (

    select * from {{ ref('mediapulse_base', 'stg_streaming__subscriptions_lifecycle_rec') }}

)

select streaming.*, staff.role
from streaming
left join staff
    on streaming.user_id = staff.user_id
