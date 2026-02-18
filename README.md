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

* To simplify obserfability , I put cleaning macroses in Mart and not in Stage models. All cleaning should be done in Stage, joining and calculation of metrics in Marts.

---

### 2.2 dbt and Sources

---

I use modular, reusable metric pipelines and dbt models.

---

*Please find here an example dbt project structure:  
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

* Outliers 100 mln, 10000 in Metrics
* Behavioral metric columns contain missing values (NaNs)
* Intermediate funnel steps are sometimes missing while impressions or orders exist
* Spend and behavioral metrics are not always time-aligned
  * Python-based reconciliation uses maximum observed values
* Some `campaign_id` values are missing from the channels dictionary
  * Assumed `campaign_id` + `campaign_name` uniqueness within this dataset
  * Assumption does not contradict provided data
* Additional Python-based cleaning
  * Row filtering
  * Dictionary-based channel imputation
 
I identified some insights withiin datasets:
I assume that the combination of Campaign_id and Campaign_Name is unique across all provided datasets, because in 3 datasets pairs are unique. I'm aware that it could be not true, just my observation and assumption to reconcile missing values.
For example, if a given Campaign_id–Campaign_Name pair is missing from the Channel dictionary, would it be acceptable to assume that this pair is still unique and to reconcile the missing Campaign_id and Channel information using the Leads Funnel dataset for the Web Orders dataset.
I cross-checked all three datasets and found that these pairs appear to be unique, with no contradictions identified on the Leads Funnel and Web Orders datasets as well.

I added my exploratory notebook on the github.

---

### 3.2 Recommendations for the Marketing Team


---
I. Quantitative Executive Performance Summary
The Efficiency Gap: In campaigns where both pathways were tested, the Sales-Assisted CAC was €25.30 compared to €872.77 for Web Self-Service. This represents a 34.5x better return on investment through the Sales path.

The Testing Campaigns: Campaigns flagged as Test  are delivering a €49.54 CAC, while legacy Always-On campaigns has €190.10 CAC—a 74% efficiency gain through experimentation.

The Growth Ceiling: Our current blended performance is 4,640 deals at a €317 CAC. By reallocating budget toward high-efficiency channels (Sales-Assisted Facebook/Bing), we can scale to 8,093 deals while lowering the Blended CAC to €182.

**Good initiatives to start**

* **Optimize Channels**
  * High-Yield Bing Shopping has €6.75 - €18.25 CAC for Bing Shopping Sales Leads.	Extremely low competition and high product-specific intent.	There is untapped "Headroom" in Bing to offset expensive Google Search costs.	Increase Bing Shopping bids to capture 90%+ Impression Share.
  * Low lead volume for contact-form traffic
  * Opportunity to improve targeting, creatives, or structure

* **Analyse and simplify if possible the sign-up flow**
  * Lowest conversion rate in the funnel
  * Reducing friction could improve downstream performance

* **"Test" Campaign Experiments Adoption**
 * "Test" Campaign Adoption	€49 CAC (Test) vs. €190 (Live).



    
* **Predictive analytics for sales prioritization**

---

**Areas to improve**

* **CAC led Budget Realocation**
  * Sales Lead CAC (34.56 Euros) is more effective than Web CAC (2212 Euros). Success Metric for Sales Assisted process - POS Lite Deal, Web - Orders. Should be recalculated ROI. Please have a look on the Dashboard Simulation Budget Realocation.

* **Generic Search Prospecting (Web)**
  * Generic Search Prospecting (Web) having	€550.63 CAC for Search Prospecting on Web. Shifting to a "Lead Form" will capture the intent without the checkout friction.
    
* **Manual sales lead processing**
  * Limits scalability (15k Leads resulting in 12k SQLs - 80% rate)
  * Constrains sales efficiency under CAC/CBO optimization goals

---


### 3.3 Dashboard

---

* Tableau dashboard  
  https://public.tableau.com/app/profile/milana.magurina/viz/ExecituveOverviewPOSLiteCampaigns/PerformanceOverview?publish=yes

---

## Part 4 

---

During the analysis, external research was used to validate whether `campaign_id` and `campaign_name` could be treated as consistent.  
This validation confirmed that they are not fully reliable in real-world marketing data.

---

**Improvements with Automatization and AI usage**

* Six campaign IDs appear in both Web and Sales-Assisted datasets
* Introduce user-level attribution beyond first-touch or last-touch
* Apply segmentation and regression models to infer true conversion sources

---

**Expected impact**

* Improved attribution accuracy
* Reduced manual reconciliation
* More reliable and scalable campaign performance metrics
