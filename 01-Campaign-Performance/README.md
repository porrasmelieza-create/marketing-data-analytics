# Campaign Performance Analysis

Identifying which advertising campaigns convert efficiently, which are wasting budget, and what that means for next quarter's spend — built on a dataset with a documented structural limitation that shapes what this analysis can and cannot conclude.

*Part of a two-project portfolio built from one shared dataset and pipeline. See the [portfolio landing page](https://github.com/porrasmelieza-create/marketing-data-analytics/blob/main/README.md) and [shared-data-pipeline](https://github.com/porrasmelieza-create/marketing-data-analytics/tree/main/shared-data-pipeline) for the common cleaning and modeling work behind this and the companion [Customer & Revenue Analysis](../02-Customer-Revenue-Analysis).*

---

## Business Problem

A marketing team needs to know which campaign types deliver efficient conversions per dollar spent, and which campaigns are quietly wasting budget. This analysis answers that using `campaigns.csv` alone — the dataset has no shared key linking campaign records to actual customer or transaction data, so this track deliberately stays within what campaign-level data alone can support, rather than fabricating a revenue or ROAS connection that isn't there.

## Objective

- Determine which campaign types deliver the most efficient conversions per dollar spent
- Identify wasted ad spend with a defensible, repeatable definition
- Assess campaign type performance through KPIs (CTR, CPC) independent of budget

## Dataset

| File | Rows | Grain |
|---|---|---|
| `campaigns.csv` | 200 | One advertising campaign |

Full source and cleaning details for all four project files live in [`shared-data-pipeline`](https://github.com/porrasmelieza-create/marketing-data-analytics/tree/main/shared-data-pipeline).

## Tools Used
 
| Tool | Used for |
|---|---|
| Excel / Power Query | Exploratory data analysis, formula-based data quality checks |
| Microsoft SQL Server | Primary cleaning pipeline, data modeling, validated business-question queries |
| Power BI | Data modeling, DAX measures, three-page interactive dashboard |

## Data Cleaning Highlights

Full script: [`shared-data-pipeline/sql/01_staging_and_cleaning.sql`](https://github.com/porrasmelieza-create/marketing-data-analytics/blob/main/shared-data-pipeline/sql/01_staging_and_cleaning.sql)

| Issue | Resolution |
|---|---|
| `conversion_rate` had missing values | Recalculated from `conversions / clicks` where both were present, rather than left blank or guessed |
| `roi` had missing values | Left `NULL`. No revenue column exists anywhere in the campaign data to recompute it from |

## Data Model

`Campaigns_Clean` is a self-contained, denormalized fact table — attributes and measures kept in one table since the grain doesn't support splitting into a separate dimension. It joins to `DimDate` only. Full build script: [`shared-data-pipeline/sql/02_data_model_build.sql`](https://github.com/porrasmelieza-create/marketing-data-analytics/blob/main/shared-data-pipeline/sql/02_data_model_build.sql).

## KPIs

| KPI | Formula | Calculated In |
|---|---|---|
| CTR % | clicks / impressions | DAX |
| Conversion Rate % | conversions / clicks | SQL, DAX |
| Cost Per Click | budget / clicks | DAX |
| Cost Per Conversion | budget / conversions | DAX |
| Average ROI % | average function for ROI | DAX |

**Notes:**
- All ratio-based DAX measures use `DIVIDE()` rather than the `/` operator, deliberately to avoid erroring when a filtered slice produces a zero denominator.
- Average ROI is passed-through. It is unverifiable because no revenue column exists to check it against.

## Business Questions

1. Which campaign types have the lowest cost per conversion?
2. Does higher campaign budget correlate with higher conversion rate?
3. How does campaign performance trend over time?
4. Which campaign types have the best CTR and CPC, independent of how much was spent?

## SQL Analysis

Full query set: [`sql/03_campaign_business_questions.sql`](https://github.com/porrasmelieza-create/marketing-data-analytics/blob/main/01-Campaign-Performance/03_campaign_business_questions.sql).

**Q1: Which campaign types have the lowest cost per conversion?**
```sql

SELECT
    campaign_type,
    COUNT(*)                       AS campaign_count,
    SUM(budget)                    AS total_budget,
    SUM(conversions)               AS total_conversions,
    ROUND(SUM(budget) / NULLIF(SUM(conversions), 0), 2) AS cost_per_conversion
FROM Campaigns_Clean
WHERE budget IS NOT NULL AND conversions IS NOT NULL
GROUP BY campaign_type
ORDER BY cost_per_conversion ASC;

```

This query computes for cost per conversion and returns it by campaign type arranged from lowest to highest. The result implies that Search Engine campaigns are the most cost-efficient channel for winning a customer, meaning less ad budget is spent to secure a single conversion here compared to any other campaign type.

## Power BI Dashboard

Dashboard file (shared with the companion project): [`shared-data-pipeline/powerbi/campaign_and_revenue_dashboard.pbix`](https://github.com/porrasmelieza-create/marketing-data-analytics/blob/main/shared-data-pipeline/powerbi/marketing_dashboard.pbix). Screenshots: [`shared-data-pipeline/powerbi/screenshots`](../shared-data-pipeline/powerbi/screenshots).

**Executive Overview** — Campaign KPIs shown alongside revenue KPIs but visually separated, so the two tracks are never implied to be related. Carries an explicit note: *"ROI/ROAS metrics were excluded due to unverifiable cost/revenue reporting in the source data."*

**Campaign Performance** — CTR, Conversion Rate, CPC, CPA as headline KPIs. A Budget vs. Conversions scatter plot, color-coded by a custom **Spend Efficiency** segmentation (High Efficiency / Other / Wasted Spend), built directly from calculated DAX columns.

## Key Findings

**1. A small number of campaigns are dramatically more efficient than the rest, independent of budget size.**
Several campaigns achieved conversion volumes several times higher than campaigns spending 3–4x more budget. The custom Spend Efficiency segmentation confirms this isn't a visual artifact — it's a formal top/bottom-quartile pattern. *Recommendation: reallocate a defined portion of budget from campaigns flagged "Wasted Spend" toward the campaign type/segment behind the "High Efficiency" outliers.*

**2. A quantifiable share of ad spend is going toward campaigns that convert poorly.**
The `Total Wasted Spend` and `Wasted Spend Campaign Count` DAX measures give an exact dollar figure and campaign count for this segment, converting "some campaigns look inefficient" into a specific, actionable budget-reallocation target.

**3. Conversion rate by target segment does not simply track campaign type or spend.**
The highest-converting segments include groups like re-engagement-oriented audiences, at sample sizes comparable to every other segment (8–16 campaigns each) — so the pattern isn't a small-sample artifact. This complicates a simple "bigger budget/more active audience converts better" narrative and is worth further targeting investigation.

## Business Recommendations

- Reallocate budget away from campaigns flagged "Wasted Spend" toward the campaign type/segment behind the high-efficiency outliers
- Use the `Total Wasted Spend` measure as a concrete, defensible number in the next budget-planning cycle
- Investigate why lower-spend, re-engagement-style segments outperform on conversion rate before assuming higher spend is always the right lever

## Limitations

- No key connects `campaigns.csv` to customers, transactions, or interactions — campaign-level revenue attribution, true ROAS, and customer acquisition cost cannot be calculated from this data
- `roi` in `campaigns.csv` is a given, unverifiable figure with no revenue column to check it against

## Potential Next Steps

- If a campaign-to-customer bridge table became available, re-run this analysis with true ROAS and CAC metrics

## Repository Structure

```
01-Campaign-Performance-Analysis/
├── README.md                                    ← this file
└── sql/
    └── 03_campaign_business_questions.sql

../shared-data-pipeline/                         ← shared with Customer & Revenue Analysis
├── data/raw/
├── documentation/
├── excel/
│   └── EDA_Workbook.xlsx
├── sql/
│   ├── 01_staging_and_cleaning.sql
│   └── 02_data_model_build.sql
└── powerbi/
    ├── marketing_dashboard.pbix
    └── screenshots/
```
