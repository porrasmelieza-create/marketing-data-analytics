# Customer & Revenue Analysis

Understanding how customers actually generate revenue, what drives it, who's engaged but not converting, and where the growth and risk segments sit, using the transactional side of a dataset that's fully joinable on `customer_id`.

*Part of a two-project portfolio built from one shared dataset and pipeline. See the [portfolio landing page](https://github.com/porrasmelieza-create/marketing-data-analytics/blob/main/README.md) and [shared-data-pipeline](https://github.com/porrasmelieza-create/marketing-data-analytics/tree/main/shared-data-pipeline) for the common cleaning and modeling work behind this and the companion [Campaign Performance Analysis](https://github.com/porrasmelieza-create/marketing-data-analytics/tree/main/01-Campaign-Performance).*

---

## Business Problem

A business needs to understand which products, geographies, and customer behaviors are actually driving revenue. Understanding where the risk sits, customers who are registered but never purchase, or engaged but never convert are also needed. This analysis uses `customers.csv`, `interactions.csv`, and `transactions.csv`, which are fully joinable on `customer_id`, independent of the campaign data (which shares no key with these tables — see the companion project for why that split exists).

## Objective

- Identify revenue drivers, customer behavior patterns, and geographic/product concentration in the transactional data
- Quantify how much of the engaged customer base actually converts to a purchase
- Surface at-risk and underperforming customer segments with enough specificity to act on

## Dataset

| File | Rows | Grain |
|---|---|---|
| `customers.csv` | 5,000 | One customer profile |
| `interactions.csv` | 100,000 | One customer touchpoint (page view, cart add, checkout, etc.) |
| `transactions.csv` | 32,295 | One purchase transaction |

Full source and cleaning details for all four project files live in [`shared-data-pipeline`](../shared-data-pipeline).

## Tools Used
 
| Tool | Used for |
|---|---|
| Excel / Power Query | Exploratory data analysis, formula-based data quality checks, pivot table |
| Microsoft SQL Server | Primary cleaning pipeline, data modeling, validated business-question queries |
| Power BI | Data modeling, DAX measures, three-page interactive dashboard |

## Data Cleaning Highlights

Full script: [`shared-data-pipeline/sql/01_staging_and_cleaning.sql`](https://github.com/porrasmelieza-create/marketing-data-analytics/blob/main/shared-data-pipeline/sql/01_staging_and_cleaning.sql)

| Issue | Resolution |
|---|---|
| `zip_code` stored as a numeric type, risking loss of leading zeros | Reformatted to a zero-padded text field; documented as a possible pre-existing data-loss point, not fully recoverable |
| `store_location` mixed two grains ("Online" vs. "City, ST") in one column | Split into `channel_type`, `store_city`, `store_state`
| `discount_applied` had ~2% missing values | Left `NULL` rather than assumed to be 0% — investigated for patterns before deciding, treated as 0% only inside the final revenue calculation, with the assumption explicitly logged (585 rows / ~1.9% of transactions affected) |
| Numeric fields critical to revenue (`quantity`, `price`) had missing values | Left `NULL` and excluded from calculations rather than imputed |

## Data Model

`FactTransactions` and `FactInteractions` are fully relational, joined to `DimCustomer` and `DimDate`. No many-to-many relationships exist anywhere in the model. Full build script: [`shared-data-pipeline/sql/02_data_model_build.sql`](https://github.com/porrasmelieza-create/marketing-data-analytics/blob/main/shared-data-pipeline/sql/02_data_model_build.sql).

## KPIs

| KPI | Formula | Calculated In |
|---|---|---|
| Total Revenue | SUM(revenue, net of discount) | DAX |
| Average Order Value | Total Revenue / Total Transactions | DAX |
| Revenue Per Customer | Total Revenue / Customers with Purchases | DAX |
| Purchase Frequency | Total Transactions / Customers with Purchases | DAX |
| Behavioral Conversion Rate % | Customers with Purchases / Engaged Customers | SQL base counts + DAX |

All ratio-based DAX measures use `DIVIDE()` rather than the `/` operator, deliberately to avoid erroring when a filtered slice produces a zero denominator.

## Business Questions

1. Which product categories generate the most total revenue?
2. How does total revenue trend month-over-month?
3. Which states generate the highest revenue and revenue-per-customer?
4. What % of engaged customers actually purchase?
5. Do discount users have a different AOV than non-discount users?
6. Which channel has the longest engagement before a purchase?
7. What share of customers have never purchased, and does it vary by state or age?

## SQL Analysis

Full query set: [`sql/03_customer_revenue_business_questions.sql`](./sql/03_customer_revenue_business_questions.sql).

**Behavioral conversion rate — a real, measurable substitute for unverifiable campaign ROAS**
```sql
WITH EngagedCustomers AS (
    SELECT DISTINCT customer_id
    FROM FactInteractions
),
PurchasingCustomers AS (
    SELECT DISTINCT customer_id
    FROM FactTransactions
)
SELECT
    (SELECT COUNT(*) FROM EngagedCustomers)    AS total_engaged_customers,
    (SELECT COUNT(*) FROM PurchasingCustomers) AS total_purchasing_customers,
    ROUND(
        (SELECT COUNT(*) FROM PurchasingCustomers) * 100.0
        / NULLIF((SELECT COUNT(*) FROM EngagedCustomers), 0)
    , 2) AS behavioral_conversion_rate_pct;
```
This metric defines conversion using actual recorded transactions, cross-checked separately against the interaction log for consistency.

Full query set: [`sql/01_staging_and_cleaning.sql`](https://github.com/porrasmelieza-create/marketing-data-analytics/blob/main/shared-data-pipeline/sql/01_staging_and_cleaning.sql).

**Revenue calculation with a documented discount assumption**
```sql
CREATE VIEW vw_Transactions_Revenue AS
SELECT *,
    quantity * price * (1 - ISNULL(discount_applied, 0) / 100.0) AS line_revenue
FROM Transactions_Clean
WHERE quantity IS NOT NULL AND quantity > 0
  AND price IS NOT NULL AND price >= 0;
```
An unknown discount is treated as 0% only inside this specific calculation — `discount_applied` itself stays a true `NULL` in the underlying table, so the assumption is scoped to revenue math only and never silently overwrites the source data.

## Power BI Dashboard

Dashboard file (shared with the companion project): [`shared-data-pipeline/powerbi/campaign_and_revenue_dashboard.pbix`](https://github.com/porrasmelieza-create/marketing-data-analytics/blob/main/shared-data-pipeline/powerbi/marketing_dashboard.pbix). Screenshots: [`shared-data-pipeline/powerbi/screenshots`](../shared-data-pipeline/powerbi/screenshots).

**Executive Overview** — Revenue KPIs shown alongside campaign KPIs but visually separated (divider, distinct card colors), so the two tracks are never implied to be related. Monthly revenue trend is the anchor time-series visual.

**Customer & Revenue Behavior** — Revenue by product category, revenue by state (geographic map), average session duration by channel, and average order value by discount tier. Includes a flagged "Customers with Zero Purchases" KPI card.

## Key Findings

**1. Average order value holds steady through moderate discount tiers, then drops sharply at the highest tier.**
AOV stays roughly flat across 0–15% discount tiers, then falls noticeably at the 30% tier. Stated as correlational, not causal — worth checking whether the 30% tier is concentrated in lower-priced clearance categories before concluding the discount itself is driving smaller baskets.

**2. The measured behavioral conversion rate (92.17%) is implausibly high relative to real-world benchmarks.**
Flagged honestly as a likely characteristic of a synthetic/practice dataset rather than a representative business finding — stated as a limitation, not presented as an actionable result.

**3. Roughly 8% of the registered customer base has never made a purchase.**
397 of 5,000 customers have zero transaction history. Whether this is a stagnant segment or simply recently-registered customers depends on registration-date patterns within that group, which determines whether the right response is "monitor" or "targeted win-back campaign."

## Business Recommendations

- Investigate the product-category composition of the 30% discount tier before deciding whether to adjust that promotion's targeting
- Build a win-back segment targeting the 397 never-purchased customers, prioritized by registration recency
- Treat the 92.17% behavioral conversion rate as a dataset characteristic, not a benchmark to replicate elsewhere

## Limitations

- `zip_code` leading zeros were likely lost prior to any cleaning step performed in this project, and cannot be fully recovered
- The 92.17% behavioral conversion rate is implausibly high relative to real-world benchmarks, suggesting a synthetic/practice dataset rather than production data
- Discount-tier AOV differences are correlational, not proven causal
- No key connects this data to `campaigns.csv` — campaign-level revenue attribution and CAC cannot be calculated from this data (see the [Campaign Performance Analysis](https://github.com/porrasmelieza-create/marketing-data-analytics/tree/main/01-Campaign-Performance) for that track)

## Potential Next Steps

- Investigate the 30% discount tier's product mix to determine whether the AOV drop is compositional or behavioral
- Build and test an actual win-back campaign for the 397 never-purchased customers, then measure its effect
- If a campaign-to-customer bridge table became available, re-run both tracks together with true ROAS and CAC metrics

## Repository Structure

```
02-Customer-Revenue-Analysis/
├── README.md                                    ← this file
└── sql/
    └── 03_customer_revenue_business_questions.sql

../shared-data-pipeline/                         ← shared with Campaign Performance Analysis
├── data/raw/
├── sql/
│   ├── 01_staging_and_cleaning.sql
│   └── 02_data_model_build.sql
├── excel/
└── powerbi/
    ├── campaign_and_revenue_dashboard.pbix
    └── screenshots/
```
