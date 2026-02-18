-- models/marts/mart_marketing_performance.sql
-- 1) normalize join keys (country_code, campaign_id)
-- 2) clean text fields (campaign_name, channels)
-- 3) coalesce using NULLIF_BLANK so blanks don't win
-- 4) dedupe within grain by max combined spend
-- 5) incremental filter is now applied INSIDE each upstream CTE,
-- 6) warehouse only scans the lookback window instead of the full history before filtering.

{{config(
    materialized='incremental',
    unique_key=['date', 'campaign_id', 'campaign_name'],
    on_schema_change='sync_all_columns'
) }}

 --campaign_name is optional if campaign_id is a unique substance

with dim_channels as (
    select * from {{ ref('dim_campaign_channels') }}
),
fct_web as (
    select
        date,
        {{ normalize_country("country_code") }}                                   as country_code,
        cast(trim(cast(campaign_id as varchar)) as varchar)                        as campaign_id,
        total_spend_eur,
        nb_of_sessions,
        nb_of_signups,
        nb_of_orders,
        nb_of_poslite_items_ordered
    from {{ ref('fct_web_orders_daily') }}
    {% if is_incremental() %}
    where date >= (select max(date) - interval '7 days' from {{ this }})
    {% endif %}
),

fct_leads as (
    select
        date,
        {{ normalize_country("country_code") }}                                   as country_code,
        cast(trim(cast(campaign_id as varchar)) as varchar)                        as campaign_id,
        total_impressions,
        total_clicks,
        total_spend,
        total_leads,
        total_sqls,
        total_meeting_done,
        total_signed_leads,
        total_pos_lite_deals,
        {{ clean_string("channel_3") }}                                              as l_channel_3_clean,
        {{ clean_string("channel_4") }}                                              as l_channel_4_clean,
        {{ clean_string("channel_5") }}                                              as l_channel_5_clean
    from {{ ref('fct_sales_assisted_daily') }}
    {% if is_incremental() %}
    where date >= (select max(date) - interval '7 days' from {{ this }})
    {% endif %}
),

combined as (
    select
        coalesce(w.date, l.date)                                                   as date,
        coalesce(w.country_code, l.country_code)                                   as country_code,
        coalesce(w.campaign_id, l.campaign_id)                                     as campaign_id,

        w.total_spend_eur,
        w.nb_of_sessions,
        w.nb_of_signups,
        w.nb_of_orders,
        w.nb_of_poslite_items_ordered,

        l.total_impressions,
        l.total_clicks,
        l.total_spend,
        l.total_leads,
        l.total_sqls,
        l.total_meeting_done,
        l.total_signed_leads,
        l.total_pos_lite_deals,

        l.l_channel_3_clean,
        l.l_channel_4_clean,
        l.l_channel_5_clean

    from fct_web w
    full outer join fct_leads l
        on  w.date        = l.date
        and w.country_code IS NOT DISTINCT FROM l.country_code
        and w.campaign_id = l.campaign_id
),

channels_resolved as (
    select
        c.date,
        c.country_code,
        c.campaign_id,

        c.total_spend_eur,
        c.nb_of_sessions,
        c.nb_of_signups,
        c.nb_of_orders,
        c.nb_of_poslite_items_ordered,

        c.total_impressions,
        c.total_clicks,
        c.total_spend,
        c.total_leads,
        c.total_sqls,
        c.total_meeting_done,
        c.total_signed_leads,
        c.total_pos_lite_deals,

        c.l_channel_3_clean,
        c.l_channel_4_clean,
        c.l_channel_5_clean,

        {{ clean_string("d.campaign_name") }}                                        as campaign_name_raw,
        lower(regexp_replace(trim({{ clean_string("d.campaign_name") }}), '\s+', '_', 'g'))
                                                                                   as campaign_name_slug,
        cast(trim(d.campaign_period_budget_category) as varchar)                    as campaign_period_budget_category,

        {{ clean_string("d.channel_3") }}                                            as d_channel_3_clean,
        {{ clean_string("d.channel_4") }}                                            as d_channel_4_clean,
        {{ clean_string("d.channel_5") }}                                            as d_channel_5_clean

    from combined c
    left join dim_channels d
        on c.campaign_id = d.campaign_id
),

enriched as (
    select
        * exclude (campaign_name_raw, campaign_name_slug),

        {{ nullif_blank(clean_string("campaign_name_raw")) }}                       as campaign_name,

        campaign_id || '__' || coalesce(
            nullif(campaign_name_slug, ''), 'unknown'
        )                                                                          as campaign_key,

        coalesce(
            {{ nullif_blank("d_channel_3_clean") }},
            {{ nullif_blank("l_channel_3_clean") }}
        ) as channel_3,

        coalesce(
            {{ nullif_blank("d_channel_4_clean") }},
            {{ nullif_blank("l_channel_4_clean") }}
        ) as channel_4,

        coalesce(
            {{ nullif_blank("d_channel_5_clean") }},
            {{ nullif_blank("l_channel_5_clean") }}
        ) as channel_5

    from channels_resolved
),

windowed as (
    select
        *,

        coalesce(total_spend_eur, 0) + coalesce(total_spend, 0) as total_spendings,
 
 --campaign_name is optional in row_number() if campaign_id is unique substance
        row_number() over (
            partition by date, campaign_id, campaign_name
            order by (coalesce(total_spend_eur, 0) + coalesce(total_spend, 0)) desc
        ) as spend_rank

    from enriched
),

max_spend_rows as (
    select * from windowed where spend_rank = 1
),

final as (
    select
        date,
        country_code,
        campaign_id,
        campaign_key,
        campaign_name,
        campaign_period_budget_category,
        channel_3,
        channel_4,
        channel_5,

        total_spendings,

        nb_of_sessions               as sessions,
        nb_of_signups                as signups,
        nb_of_orders                 as orders,
        nb_of_poslite_items_ordered  as poslite_items_ordered,

        total_impressions            as impressions,
        total_clicks                 as clicks,
        total_leads                  as leads,
        total_sqls                   as sqls,
        total_meeting_done           as meeting_done,
        total_signed_leads           as signed_leads,
        total_pos_lite_deals         as pos_lite_deals,

        case
            when coalesce(total_pos_lite_deals, 0) > 0
            then total_spendings / nullif(total_pos_lite_deals, 0)
            else null
        end as cac_per_pos_lite_deal,

        case
            when coalesce(total_leads, 0) > 0
            then coalesce(cast(total_meeting_done as numeric), 0.0)
                 / nullif(total_leads, 0)
            else null
        end as conversion_rate_leads_to_meeting

    from max_spend_rows
)

select * from final

{% if is_incremental() %}
    where date >= (select max(date) - interval '7 days' from {{ this }})
{% endif %}
