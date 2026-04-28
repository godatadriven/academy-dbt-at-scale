{% snapshot snap_ads__campaigns %}

{{
    config(
        target_schema='snapshots',
        unique_key='campaign_id',
        strategy='check',
        check_cols=['budget_cents', 'end_date', 'campaign_type'],
    )
}}

select
    campaign_id,
    advertiser_id,
    campaign_name,
    campaign_type,
    budget_cents,
    start_date,
    end_date
from {{ source('ads', 'campaigns') }}

{% endsnapshot %}