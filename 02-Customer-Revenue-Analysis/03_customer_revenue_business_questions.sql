-- ============================================
-- STEP 5: ANALYSIS
-- ============================================

-- TRACK B: CUSTOMER & REVENUE BEHAVIOR

-- Q1: Which product categories generate the most total revenue?

SELECT
    product_category,
    COUNT(*)                    AS transaction_count,
    SUM(line_revenue)           AS total_revenue,
    ROUND(AVG(line_revenue), 2) AS avg_line_revenue
FROM FactTransactions
GROUP BY product_category
ORDER BY total_revenue DESC;

-- Q2: How does total revenue trend month over month across the observed period?

SELECT
    d.[Year],
    d.[MonthNumber],
    d.[MonthName],
    SUM(t.line_revenue) AS total_revenue,
    COUNT(DISTINCT t.transaction_id) AS transaction_count
FROM FactTransactions t
JOIN DimDate d ON t.transaction_date = d.DateKey
GROUP BY d.[Year], d.[MonthNumber], d.[MonthName]
ORDER BY d.[Year], d.[MonthNumber];

-- Q3: Which states/geographies geenrate the highest revenue and revenue per customer?

SELECT
    c.state,
    COUNT(DISTINCT t.customer_id)          AS customers_with_purchases,
    SUM(t.line_revenue)                     AS total_revenue,
    ROUND(SUM(t.line_revenue) / NULLIF(COUNT(DISTINCT t.customer_id), 0), 2) AS revenue_per_customer
FROM FactTransactions t
JOIN DimCustomer c ON t.customer_id = c.customer_id
WHERE c.state IS NOT NULL
GROUP BY c.state
ORDER BY total_revenue DESC;

-- Q4: What % of engaged customers go on to actually purchase?

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

-- Q5: Do customers who use discounts have a meaningfully different average order value than those who dont?

SELECT
    discount_applied AS discount_tier,
    COUNT(*)                    AS transaction_count,
    ROUND(AVG(line_revenue), 2)      AS avg_order_value
FROM FactTransactions
WHERE discount_applied IS NOT NULL
GROUP BY discount_applied
ORDER BY discount_applied;

-- Q6: Which channel has the longest engagement before a purchase?

WITH SessionDurations AS (
    SELECT
        session_id,
        channel,
        SUM(duration) AS session_total_duration
    FROM FactInteractions
    WHERE duration IS NOT NULL
    GROUP BY session_id, channel
)
SELECT
    channel,
    COUNT(*)                              AS session_count,
    ROUND(AVG(session_total_duration), 2) AS avg_session_duration_sec
FROM SessionDurations
GROUP BY channel
ORDER BY avg_session_duration_sec DESC;

-- Q7: What share of customers have never purchase, and does it vary by state or age?

SELECT
    c.state,
    COUNT(DISTINCT c.customer_id)                                    AS total_customers,
    COUNT(DISTINCT t.customer_id)                                    AS customers_with_purchases,
    COUNT(DISTINCT c.customer_id) - COUNT(DISTINCT t.customer_id)    AS never_purchased,
    ROUND(
        (COUNT(DISTINCT c.customer_id) - COUNT(DISTINCT t.customer_id)) * 100.0
        / NULLIF(COUNT(DISTINCT c.customer_id), 0)
    , 2) AS pct_never_purchased
FROM DimCustomer c
LEFT JOIN FactTransactions t ON c.customer_id = t.customer_id
WHERE c.state IS NOT NULL
GROUP BY c.state
ORDER BY pct_never_purchased DESC;