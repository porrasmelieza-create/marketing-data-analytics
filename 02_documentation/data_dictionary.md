# Data Dictionary

### Understanding the tables

| File | Rows | Column | Grain |
|---|---|---|---|
| campaigns.csv | 200 | 12 | One advertising campaign |
| customers.csv | 5,000 | 12 | One customer profile |
| interactions.csv | 100,000 | 8 | One digital/in-store customer activity |
| transactions.csv | 32,295 | 10 | One completed purchase transaction |

### Table 01: Campaigns

| Column | Description | Expected Type | Actual Type | Business Meaning | Action |
|---|---|---|---|---|---|
| campaign_id | Unique campaign identifier | str/UUID | str | Primary key | Retain |
| campaign_name | Marketing-facing campaign name | str | str | Human label, not unique | Retain |
| start_date/end_date | Campaign dates | date | str | Defines duration | Transform into date |
| target_segment | Intended audience for the campaign | str | str | Marketing intent, not a verified join key | Retain |
| budget | Planned/spent ad budget | float | float | Cost input for ROI/efficiency metrics | Retain |
| impressions | Ad views | int | float | Reach metric | Transform into int |
| clicks | Ad clicks | int | float | Engagement metric | Transform into int |
| conversions | Attributed conversions | int | float | Outcome metric | Transform into int |
| conversion_rate | Conversions/clicks, given directly | float | float | Efficiency metric | Retain, validate |
| roi | Return on investment, given directly | float | float | Cannot be independently validated (no column to check it against) | Retain, flag as unverifiable |

### Table 02: Customers

| Column | Description | Expected Type | Actual Type | Business Meaning | Action |
|---|---|---|---|---|---|
| customer_id | Unique customer identifier | str/UUID | str | Primary key | Retain |
| full_name | Customer name | str | str | Personally Identifiable Information (PII), not analytically needed | Retain (exclude from published dashboards) |
| age | Customer age | int | float | Demographic segmentation | Transform into int |
| gender | Self-reported gender | str | str | Demographic segmentation | Retain |
| email / phone | Contact info | str | str | PII | Retain (exclude from published dashboards) |
| street_address / city / state / zip_code | Location | str | zip is float | Geographic segmentation | Transform zip into str |
| registration_date | Signup date | date | str | Tenure, cohort analysis | Transform into date |
| preferred_channel | Stated channel preferrence | str | str | Compare stated vs. actual | Retaim |

### Table 03: Interactions

| Column | Description | Expected Type | Actual Type | Business Meaning | Action |
|---|---|---|---|---|---|
| interaction_id | Unique interaction identifier | str/UUID | str | Primary key | Retain |
| customer_id | Linked customer | str/UUID | str | FK to customers | Retain |
| channel | Where interaction occurred (web/mobile app/in-store kiosk) | str | str | Channel behavior analysis | Retain |
| interaction_type | Action taken (14 types: page_view, checkout, purchase, etc.) | str | str | Funnel-stage analysis | Retain |
| interaction_date | Timestamp of interaction | datetime | str | Time-based funnel analysis | Transform into datetime |
| duration | Seconds spent on the action | float | float | Engagement depth | Retain |
| page_or_product | What was viewed / interacted with | str | str | Product / page interest | Retain |
| session_id | Groups interactions into a visit | str | str | Session-level funnel construction | Retain |

### Table 04: Transactions

| Column | Description | Expected Type | Actual Type | Business Meaning | Action |
|---|---|---|---|---|---|
| transaction_id | Unique transaction identifier | str/UUID | str | Primary key | Retain |
| customer_id | Linked customer | str/UUID | str | FK to customers | Retain |
| product_name / product_category | What was bought | str | str | Product performance analysis | Retain |
| quantity | Units purchased | int | float | Revenue calc input | Transform into int |
| price | Unit price | float | float | Revenue calc input | Retain, verify |
| transaction_date | Purchase date | date | str | Time trend / cohort analysis | Transform into date |
| store_lcoation | Where purchased | str | str | Channel + geography | Transform into 2 fields |
| payment_method | How paid | str | str | Payment behavior | Retain |
| discount_applied | % discount given | float | float | Margin / promo analysis | Retain |


