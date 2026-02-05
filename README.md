Marketing Campaigns Performance Review

Analyze and model POS Lite marketing and sales funnels into a scalable KPI mart, including QA and a dashboard proposal.

Part 1 — Metrics
1.1. Top KPIs

Question:
What are the top 3–5 KPIs the Mission Lead should track to evaluate the health of both the Self-Service (Web) and Sales-Assisted funnels?

This project defines a simple metric tree to evaluate campaign efficiency and revenue health.

<img width="2215" height="1805" alt="image" src="https://github.com/user-attachments/assets/ba7088b3-cd84-42fb-a972-650464f0ab8f" />

The top three KPIs the Mission Lead should track are:

CAC (or CPO) — Cost per Ordered POS Lite / Deal
Measures the real impact of marketing and sales on revenue.

Conversion Rate
Tracks funnel effectiveness. For this assessment, I calculate conversion specifically from Leads to Meetings.

Total Spend
Enables budget control and supports forecasting and predictive modeling.

1.2. Cost per Lead vs. Sales Cycle Duration

Question:
If Cost per Lead is decreasing while Sales Cycle Duration is increasing, is that good or bad?

Answer:
This should be evaluated as a system with interdependent metrics.

Cost per Lead (CPL) ↓ — Positive signal
The company is acquiring interest more cost-efficiently, which improves unit economics if lead quality remains stable.

Sales Cycle Duration ↑ — Context-dependent

Negative scenario:
Longer deal cycles usually mean slower revenue realization, reduced sales throughput, and increased sales effort per deal. For transaction-based revenue models, this delays volume ramp-up.

Potentially positive scenario:
If the longer cycle is driven by moving upmarket to larger merchants with higher expected transaction volume or LTV—and close rates and payback periods remain strong—this may be acceptable.

In most cases, falling CPL combined with rising cycle duration signals lower-intent or lower-quality leads.

Part 2 — Data Structure
2.1. Data Model

Please see the model definition in:
mart_marketing_performance.sql

2.2. dbt and Sources

I use modular, reusable metric pipelines and dbt models.

The example dbt project structure is available in the poslite-missing-analytics folder.

Assumptions and practices:

Each source includes _etl_loaded_at

Freshness checks detect ingestion delays

Source-level tests ensure schema stability and data quality

2.2.1. Freshness Policy

Warning: 12–17 hours

Error: 24 hours

Source tests can be run independently.

2.2.2. Snapshots & Metric Reconciliation

Marketing metrics (e.g., spend and impressions) may be updated after ingestion.
dbt snapshots are used to preserve history and reconcile changes.

Snapshots are not used as dbt models, but as sources

Timestamp-based snapshots use _etl_loaded_at

Stored in a dedicated snapshots schema

Surrogate Key Proposal

A deterministic surrogate key is built from:

campaign_id, campaign_name

date, country_code

channel_3, channel_4, channel_5

_etl_loaded_at

Keys are generated using dbt macros for null safety and consistency.

Reconciliation Logic

Daily spend and impressions are reconciled using MAX() per campaign and day

This matches dashboard logic, which requires the latest known daily values

2.2.3. Intermediate Layer (Business Logic)

Responsibilities:

Apply core business rules and reconciliation logic

Join fact tables to campaign and channel dimensions

Reconcile late-arriving data using snapshots

Align grains across funnels (daily × campaign × country)

Build unified funnel structures

Spend, impressions, and funnel steps are reconciled using MAX() per day and campaign.
All assumptions are documented and enforced consistently.

2.2.4. Testing Strategy

Source tests: freshness, schema validation, referential integrity

Singular tests: business assertions (e.g., non-negative spend)

Model tests: not_null, unique, accepted_values, funnel monotonicity

2.2.5. Orchestration & Production Readiness

Models run daily

Snapshots execute before downstream models

Part 3 — Dataset Exploration
3.1. Data Quality Issues Identified

Several behavioral metric columns contain missing values (NaNs), with frequent gaps.

In some cases, impressions and ordered/deal metrics are present, while intermediate funnel metrics are missing.

Time-based alignment between spend and behavioral metrics (e.g., clicks) is inconsistent; clicks do not always peak when spend peaks.

To address this, a Python-based approach was used to select the maximum observed values for clicks and spend.

Some campaign_id values were missing from the channels dictionary.

Based on dataset exploration, campaign_id and campaign_name were assumed to form a unique mapping within this dataset.

Although external sources suggest this is not always true, the assumption does not introduce contradictions in the provided data.

Additional data cleaning was performed in Python, including row filtering and dictionary-based imputation of channel attributes.

3.2. Recommendations for the Marketing Team

Based on dashboard insights and prior analytical experience:

Good initiatives to start

Leverage predictive analytics for sales prioritization
Using a 28-day rolling window (aligned with a two-week sales cycle), spikes in total orders are often driven by contact-form submissions rather than web orders.
This indicates an opportunity to automate lead segmentation and build a machine learning model to predict high-value leads for sales prioritization.

Simplify the sign-up flow
Funnel analysis shows the sign-up stage has the lowest conversion rate. Reducing friction or steps in onboarding could materially improve downstream performance.

Further optimize Facebook targeting
Facebook generates a relatively low volume of silent leads, particularly for contact-form traffic. Improvements may be possible through audience refinement, creative optimization, or campaign restructuring.

Areas to revise

Relying solely on manual sales lead processing
Given observed lead volumes and CAC/CBO optimization goals, manual processes limit scalability and may constrain revenue growth.

Continue (with optimization)

Spend optimization using rolling performance windows
The 28-day rolling window is appropriate, as it captures the full sales cycle and ensures metric completeness.

Optimizing CAC / cost per sale rather than surface metrics
This remains the correct optimization objective, but should be paired with automated sales-lead workflows to unlock full efficiency gains.

3.3. Dashboard

Dashboard link:
https://public.tableau.com/app/profile/milana.magurina/viz/Pos-LiteCampaignsPerformanceOverview/PerformanceOverview?publish=yes

Part 4 — Attribution & Advanced Recommendations

During the analysis, ChatGPT search was used to validate whether reconciliation between campaign_id and campaign_name could be treated as consistent. While initial review suggested this was acceptable, further external research confirmed that these fields are not fully compatible in real-world marketing data. This double validation highlighted common limitations in campaign-level attribution.

Based on this task and prior experience, additional value could be created through workflow automation and AI-driven attribution.

Key observations and recommendations:

In the dataset, six campaign IDs appear in both Web and Sales-Assisted datasets.

To improve metric reliability and reconciliation quality, I recommend introducing automated user-level attribution logic that goes beyond first-touch or last-touch models.

Apply segmentation and regression models to cluster users by behavioral patterns and better infer the true conversion source.

This approach would:

Improve attribution accuracy

Reduce manual reconciliation

Enable more reliable, scalable campaign performance metrics
