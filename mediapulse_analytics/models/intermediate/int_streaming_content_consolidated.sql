select * from {{ ref('mediapulse_base', 'stg_streaming__content_ctlg') }}
union all
select * from {{ ref("stg_streamview_legacy__content") }}