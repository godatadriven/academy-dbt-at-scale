select *, false as is_legacy from {{ ref('mediapulse_base', 'stg_streaming__content_ctlg') }}
union all
select *, true as is_legacy from {{ ref("stg_streamview_legacy__content") }}