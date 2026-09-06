<div align="center">

# 🗠 Data Analytics Portfolio
</div>

Welcome to my Data Analytics Portfolio! 👋

This repository showcases my projects and experience in data analysis, marketing analytics, and customer insights. With a background in Applied Mathematics and experience in social media and creative work, I am interested in using data to understand customer behavior, evaluate marketing performance, and support data-driven business decisions.

Below are end-to-end analytics projects covering data cleaning, SQL analysis, data modeling, and Power BI dashboarding. Both projects are built from the same source dataset and share one cleaning pipeline and one Power BI file — [`shared-data-pipeline/`](./shared-data-pipeline) for the common groundwork behind both.

## 🗁 Featured Projects
| # | Project | Description | Tools |
|---|---|---|---|
| **01** | [**Campaign Performance Analysis**](./01-Campaign-Performance) | Identifies which ad campaign types and target segments convert most efficiently, and quantifies wasted ad spend using a percentile-based classification built in DAX. | Excel · SQL · Power BI |
| **02** | [**Customer & Revenue Analysis**](./02-Customer-&-Revenue-Analysis) | Analyzes revenue drivers, customer purchase behavior, and geographic/product concentration across ~5,000 customers and 32K+ transactions. | Excel · SQL · Power BI |

## Why Two Projects From One Dataset
During initial data exploration, I found that the campaign data shares no key with the customer, transaction, or interaction data — there's no campaign_id on customer records and no customer_id on campaign records. Rather than force a false connection between ad spend and revenue, I treated this as two independent analytical tracks with one shared cleaning pipeline and a single Power BI file, and documented the boundary explicitly instead of papering over it. Each project README explains what its track can and cannot conclude on its own.

## Shared Pipeline
Both projects draw from the same raw data, cleaning scripts, data model, and dashboard file:
```
shared-data-pipeline/
├── data/raw/              ← original 4 CSVs, untouched
├── sql/
│   ├── 01_staging_and_cleaning.sql
│   └── 02_data_model_build.sql
├── excel/                 ← EDA and Power Query workbooks
└── powerbi/
    ├── campaign_and_revenue_dashboard.pbix   ← one file, both tracks
    └── screenshots/
```
See each project's README for track-specific business questions, SQL, findings, and recommendations.

## ⚙︎ Tools & Skills

**Data Analysis:** Excel, SQL, Python  
**Visualization:** Power BI, Excel, Powerpoint  
**Statistics:** Hypothesis Testing, Regression, Descriptive Statistics  
**Marketing Analytics:** Campaign Performance, Customer Segmentation

## ★ About Me

I am an Applied Mathematics graduate interested in building a career at the intersection of data, business, and creativity. I enjoy working with data to uncover patterns and insights, but I am especially interested in environments where analytics works alongside marketing, creative, and business teams.

This portfolio is a collection of my ongoing projects as I continue developing my skills and exploring real-world applications of data analytics.  

---
<div align="center">
Thank you for visiting my portfolio! ♡
</div>
