# Marketing Campaigns Performance Review

---

Analyze and model POS Lite marketing and sales funnels into a scalable KPI mart, with QA and a dashboard proposal.

---

## Part 1 — Metrics

---

### 1.1 Top KPIs

**Question**  
What are the top 3–5 KPIs the Mission Lead should track to evaluate the health of both the Self-Service (Web) and Sales-Assisted funnels?

---

Please find here a simple metric tree to evaluate campaign efficiency and revenue health:

<img width="2215" height="1805" alt="image" src="https://github.com/user-attachments/assets/596f8cec-4b24-48b2-84ee-7c30dc4c95ad" />

---

**Top KPIs to track**

* **CAC (or CPO)**  
  Cost per Ordered POS Lite / Deal  
  Measures the real impact of marketing and sales on revenue.

* **Conversion Rate**  
  Tracks funnel effectiveness.  
  For this assessment, conversion is calculated from **Leads → Meetings** only.

* **Total Spend**  
  Supports budgeting, forecasting, and predictive modeling.

---

### 1.2 Cost per Lead vs. Sales Cycle Duration

---

**Question**  
If Cost per Lead is decreasing while Sales Cycle Duration is increasing, is that good or bad?

---

**Answer**  
This should be evaluated as a system with interdependent metrics.

---

* **Cost per Lead ↓ — Positive**
  * Indicates more cost-efficient lead acquisition
  * Improves unit economics if lead quality remains stable

* **Sales Cycle Duration ↑ — Context dependent**
  * **Negative scenario**
    * Slower revenue realization
    * Lower sales throughput
    * Higher sales effort per deal
  * **Potentially positive scenario**
    * Movement upmarket to larger merchants
    * Higher expected transaction volume or LTV
    * Acceptable if close rates and payback remain strong

---

**Conclusion**  
Falling CPL combined with rising sales cycle duration often signals lower-intent or lower-quality leads.

---

## Part 2 — Data Structure

---

### 2.1 Data Model

---
Please find the sample version with macroses to clean the data here:
* Model definition:  
  `mart_marketing_performance.sql`

---

### 2.2 dbt and Sources

---

I use modular, reusable metric pipelines and dbt models.

---

* Example dbt project structure:  
  `poslite-missing-analytics`

---

**Assumptions and practices**

* Each source includes `_etl_loaded_at`
* Freshness checks detect ingestion delays
* Source-level tests ensure schema stability and data quality

---

### 2.2.1 Freshness Policy

---

* **Warning:** 12–17 hours
* **Error:** 24 hours

---

* Source tests can be run independently

---

### 2.2.2 Snapshots and Metric Reconciliation

---

Marketing metrics (e.g. spend and impressions) may be updated after ingestion.  
dbt snapshots are used to preserve history and reconcile changes.

---

**Snapshot setup**

* Used as sources, not dbt models
* Timestamp-based snapshots using `_etl_loaded_at`
* Stored in a dedicated `snapshots` schema

---

**Surrogate key proposal**

A deterministic surrogate key is built from:

* `campaign_id`
* `campaign_name`
* `date`
* `country_code`
* `channel_3`
* `channel_4`
* `channel_5`
* `_etl_loaded_at`

---

* Keys are generated using dbt macros for null safety and consistency

---

**Reconciliation logic**

* Daily spend and impressions reconciled using `MAX()` per campaign and day
* Matches dashboard logic requiring the latest known daily values

---

### 2.2.3 Intermediate Layer (Business Logic)

---

Responsibilities

* Apply core business rules and reconciliation logic
* Join facts to campaign and channel dimensions
* Reconcile late-arriving data using snapshots
* Align grains across funnels (daily × campaign × country)
* Build unified funnel structures

---

* Spend, impressions, and funnel steps reconciled using `MAX()`
* Assumptions documented and enforced consistently

---

### 2.2.4 Testing Strategy

---

* **Source tests**
  * Freshness
  * Schema validation
  * Referential integrity

* **Singular tests**
  * Business assertions (e.g. non-negative spend)

* **Model tests**
  * `not_null`
  * `unique`
  * `accepted_values`
  * Funnel monotonicity

---

### 2.2.5 Orchestration and Production Readiness

---

* Models run daily
* Snapshots execute before downstream models

---

## Part 3 — Dataset Exploration

---

### 3.1 Data Quality Issues Identified

---

* Behavioral metric columns contain missing values (NaNs)
* Intermediate funnel steps are sometimes missing while impressions or orders exist
* Spend and behavioral metrics are not always time-aligned
  * Clicks do not always peak when spend peaks
  * Python-based reconciliation uses maximum observed values
* Some `campaign_id` values are missing from the channels dictionary
  * Assumed `campaign_id` + `campaign_name` uniqueness within this dataset
  * Assumption does not contradict provided data
* Additional Python-based cleaning
  * Row filtering
  * Dictionary-based channel imputation
 
I added my exploratory notebook on the github.

---

### 3.2 Recommendations for the Marketing Team


---

**Good initiatives to start**

* **Predictive analytics for sales prioritization**
  * 28-day rolling window aligned with a two-week sales cycle
  * Contact-form submissions drive most order spikes
  * Opportunity to automate lead scoring

* **Simplify the sign-up flow**
  * Lowest conversion rate in the funnel
  * Reducing friction could improve downstream performance

* **Further optimize Facebook targeting**
  * Low silent-lead volume for contact-form traffic
  * Opportunity to improve targeting, creatives, or structure

---

**Areas to improve**

* **Manual sales lead processing**
  * Limits scalability
  * Constrains sales efficiency under CAC/CBO optimization goals

---

**Continue with optimization**

* **Spend optimization using rolling windows**
  * 28-day window captures the full sales cycle
  * Ensures data completeness

* **Optimize CAC / cost per sale**
  * Correct primary optimization metric
  * Should be paired with automated sales workflows

---

### 3.3 Dashboard

---

* Tableau dashboard  
  https://public.tableau.com/app/profile/milana.magurina/viz/Pos-LiteCampaignsPerformanceOverview/PerformanceOverview?publish=yes

---

## Part 4 

---

During the analysis, external research was used to validate whether `campaign_id` and `campaign_name` could be treated as consistent.  
This validation confirmed that they are not fully reliable in real-world marketing data.

---

**Key observations and recommendations**

* Six campaign IDs appear in both Web and Sales-Assisted datasets
* Introduce user-level attribution beyond first-touch or last-touch
* Apply segmentation and regression models to infer true conversion sources

---

**Expected impact**

* Improved attribution accuracy
* Reduced manual reconciliation
* More reliable and scalable campaign performance metrics
