select
  cast(trim(cast(campaign_id as varchar)) as varchar) as campaign_id,
  _etl_loaded_at
from {{ source('marketing', 'web_orders') }}