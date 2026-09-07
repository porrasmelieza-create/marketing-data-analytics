-- ============================================
-- STEP 5: ANALYSIS
-- ============================================

-- TRACK A: CAMPAIGN PERFORMANCE
-- Q1: Which campaign types have the lowest cost per conversion?

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

-- Q2: Which campaigns received a large budget but produced disproportionately few conversions?

SELECT
    campaign_id,
    campaign_name,
    campaign_type,
    budget,
    conversions,
    NTILE(4) OVER (ORDER BY budget DESC)      AS budget_quartile,
    NTILE(4) OVER (ORDER BY conversions ASC)  AS conversion_quartile_ascending
FROM Campaigns_Clean
WHERE budget IS NOT NULL AND conversions IS NOT NULL
ORDER BY budget DESC;

-- Flag the specific mismatch cases directly
WITH Ranked AS (
    SELECT
        campaign_id, campaign_name, campaign_type, budget, conversions,
        NTILE(4) OVER (ORDER BY budget DESC)      AS budget_quartile,
        NTILE(4) OVER (ORDER BY conversions ASC)  AS conversion_quartile_ascending
    FROM Campaigns_Clean
    WHERE budget IS NOT NULL AND conversions IS NOT NULL
)
SELECT *
FROM Ranked
WHERE budget_quartile = 1 AND conversion_quartile_ascending = 1
ORDER BY budget DESC;

-- Q3: Which target segments show the highest conversion rates?

SELECT
    target_segment,
    COUNT(*)                          AS campaign_count,
    SUM(clicks)                       AS total_clicks,
    SUM(conversions)                  AS total_conversions,
    ROUND(SUM(conversions) * 100.0 / NULLIF(SUM(clicks), 0), 2) AS conversion_rate_pct
FROM Campaigns_Clean
WHERE clicks IS NOT NULL AND conversions IS NOT NULL
GROUP BY target_segment
ORDER BY conversion_rate_pct DESC;

-- Q4: Is there a relationship beween campaign budget size and conversion rate
-- (does higher campaign budgets correlate with higher conversion rate)?

SELECT
    campaign_id,
    campaign_type,
    budget,
    conversion_rate
FROM Campaigns_Clean
WHERE budget IS NOT NULL AND conversion_rate IS NOT NULL
ORDER BY budget DESC;

-- Bucketed version for an easier-to-read trend
SELECT
    CASE
        WHEN budget < 5000  THEN '< $5K'
        WHEN budget < 15000 THEN '$5K-$15K'
        WHEN budget < 30000 THEN '$15K-$30K'
        ELSE '$30K+'
    END AS budget_bucket,
    COUNT(*)                       AS campaign_count,
    ROUND(AVG(conversion_rate), 2) AS avg_conversion_rate
FROM Campaigns_Clean
WHERE budget IS NOT NULL AND conversion_rate IS NOT NULL
GROUP BY CASE
        WHEN budget < 5000  THEN '< $5K'
        WHEN budget < 15000 THEN '$5K-$15K'
        WHEN budget < 30000 THEN '$15K-$30K'
        ELSE '$30K+'
    END
ORDER BY MIN(budget);

-- Q5: How does campaign performance trend across the observed time period?

SELECT
    YEAR(start_date)  AS campaign_year,
    MONTH(start_date) AS campaign_month,
    COUNT(*)                                                          AS campaigns_started,
    ROUND(AVG(CAST(clicks AS FLOAT) / NULLIF(impressions, 0) * 100), 2)  AS avg_ctr,
    ROUND(AVG(conversion_rate), 2)                                    AS avg_conversion_rate
FROM Campaigns_Clean
WHERE start_date IS NOT NULL
GROUP BY YEAR(start_date), MONTH(start_date)
ORDER BY campaign_year, campaign_month;

-- Q6: Which campaign types show the best CTR?

SELECT
    campaign_type,
    SUM(impressions)  AS total_impressions,
    SUM(clicks)        AS total_clicks,
    ROUND(SUM(clicks) * 100.0 / NULLIF(SUM(impressions), 0), 2) AS ctr_pct
FROM Campaigns_Clean
WHERE impressions IS NOT NULL AND clicks IS NOT NULL
GROUP BY campaign_type
ORDER BY ctr_pct DESC;

/*Pair this with Q1, don't read it alone: a campaign type can have a great CTR and a terrible
CPA at the same time (lots of cheap, low-quality clicks that rarely convert) — presenting
CTR by itself risks implying it's "the best channel" when it might just be the most clickable,
not the most efficient.*/

SELECT campaign_id, campaign_type, impressions, clicks
FROM Campaigns_Clean
WHERE clicks > impressions;