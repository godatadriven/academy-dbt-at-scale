with source as (

    select * from {{ ref('staff_members') }}

),

renamed as (

    select
        user_id,
        cast(start_date as date)    as start_date,
        name,
        email,
        phone_number,
        role

    from source

)

select * from renamed
