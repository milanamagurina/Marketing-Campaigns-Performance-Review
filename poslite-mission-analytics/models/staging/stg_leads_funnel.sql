select
  cast(trim(cast(campaign_id as varchar)) as varchar) as campaign_id,
  {{ clean_string('campaign_name') }} as campaign_name,
  {{ clean_string('channel_3') }} as channel_3,
  {{ clean_string('channel_4') }} as channel_4,
  {{ clean_string('channel_5') }} as channel_5,
  _etl_loaded_at
from {{ source('marketing', 'leads_funnel') }}