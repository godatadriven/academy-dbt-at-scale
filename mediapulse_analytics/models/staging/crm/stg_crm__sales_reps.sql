with source as (

    select * from {{ source('crm', 'sales_reps') }}

),

renamed as (

    select
        rep_id,
        rep_name,
        region,
        cast(hire_date as date)    as hire_date

    from source

)

select * from renamed
