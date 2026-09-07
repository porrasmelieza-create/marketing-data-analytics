-- ============================================
-- STEP 4: BUILDING TABLES FOR POWER BI
-- ============================================

-- 4A. DimDate
DROP TABLE IF EXISTS dbo.DimDate;

CREATE TABLE DimDate (
    DateKey        DATE PRIMARY KEY,
    [Year]         INT,
    [Quarter]      INT,
    [MonthNumber]  INT,
    [MonthName]    NVARCHAR(20),
    [DayOfWeek]    NVARCHAR(20),
    [WeekOfYear]   INT
);
GO

DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate   DATE = '2025-12-31';

;WITH DateSeq AS (
    SELECT @StartDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateSeq
    WHERE DateValue < @EndDate
)
INSERT INTO DimDate
SELECT
    DateValue, YEAR(DateValue), DATEPART(QUARTER, DateValue),
    MONTH(DateValue), DATENAME(MONTH, DateValue),
    DATENAME(WEEKDAY, DateValue), DATEPART(WEEK, DateValue)
FROM DateSeq
OPTION (MAXRECURSION 0);
GO


-- 4B. DimCustomer
DROP TABLE IF EXISTS dbo.DimCustomer;

SELECT
    customer_id,
    full_name,
    age,
    gender,
    email,
    phone,
    street_address,
    city,
    state,
    zip_code,
    registration_date,
    preferred_channel
INTO DimCustomer
FROM Customers_Clean;

-- 4C. FactTransactions
DROP TABLE IF EXISTS dbo.FactTransactions;

SELECT
    transaction_id,
    customer_id,
    product_name,
    product_category,
    quantity,
    price,
    discount_applied,
    line_revenue,
    transaction_date,
    channel_type,
    store_city,
    store_state,
    payment_method
INTO FactTransactions
FROM vw_Transactions_Revenue;

-- 4D. FactInteractions
DROP TABLE IF EXISTS dbo.FactInteractions;

SELECT
    interaction_id,
    customer_id,
    channel,
    interaction_type,
    interaction_date,
    duration,
    page_or_product,
    session_id
INTO FactInteractions
FROM Interactions_Clean;
