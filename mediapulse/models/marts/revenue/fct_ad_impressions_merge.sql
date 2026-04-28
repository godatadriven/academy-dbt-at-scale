{{                                                                                                                          
      config(                                                                                                                 
          materialized='incremental',                                                                                         
          unique_key='impression_id',
          incremental_strategy='merge',
          enabled=false                                                                                        
      )                                                                                                
  }}

  with impressions as (                                                                                                       
  
      select * from {{ ref('stg_ads__impressions') }}                                                                         
                                                                                                       
      {% if is_incremental() %}                                                                                               
          where impression_date >= dateadd('day', -3, (select coalesce(max(impression_date), '1900-01-01') from {{ this }}))
      {% endif %}                                                                                                             
                                                                                                       
  ),                                                                                                                          
                                                                                                       
  campaigns as (

      select * from {{ ref('stg_ads__campaigns') }}

  ),

  final as (

      select
          i.impression_id,
          i.campaign_id,                                                                                                      
          i.content_id,
          i.impression_date,                                                                                                  
          i.impressions_count,                                                                         
          i.clicks,                                                                                                           
          i.click_through_rate,
          c.campaign_type,                                                                                                    
          c.advertiser_id                                                                                                     
      from impressions i
      inner join campaigns c using (campaign_id)                                                                              
                                                                                                       
  )

  select * from final       