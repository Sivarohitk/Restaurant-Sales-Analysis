# Restaurant Sales Intelligence: Menu Performance, Peak Hours, and Revenue Insights

An end-to-end analytics portfolio project that turns a raw restaurant transaction file into a reproducible business case study using SQL, Python, pandas, and clear business reporting.

## Business Problem

Restaurant operators need to know which menu items drive revenue, which selling periods deserve the most staffing and inventory support, and where data quality gaps are limiting decision-making. This project analyzes transactional restaurant sales to identify product performance, demand patterns, and operational improvement opportunities.

## Dataset Overview

- Source file: `data/raw/restaurant_sales.csv`
- Records: 1,000 transactions
- Date coverage: January 4, 2022 to December 3, 2023
- Source columns:
  - `order_id`
  - `date`
  - `item_name`
  - `item_type`
  - `item_price`
  - `quantity`
  - `transaction_amount`
  - `transaction_type`
  - `received_by`
  - `time_of_sale`

## Key Business Questions

- What are total sales, total orders, average order value, and total quantity sold?
- Which products generate the most revenue and which sell the most by volume?
- Which times of day generate the strongest sales and basket values?
- How does revenue trend month over month?
- Which payment methods are most common, and where is payment data missing?
- How do beverages and fast food compare on revenue contribution and unit volume?
- Which item type and daypart combinations perform best?

## Tools Used

- SQL (MySQL 8.0 style scripts for schema, cleaning, views, and business queries)
- Python
- pandas
- matplotlib
- Jupyter Notebook

## Project Structure

```text
.
|-- README.md
|-- requirements.txt
|-- data
|   |-- raw
|   |   `-- restaurant_sales.csv
|   `-- processed
|       |-- data_quality_issues.csv
|       `-- restaurant_sales_clean.csv
|-- docs
|   |-- executive_summary.md
|   `-- legacy
|       `-- original_restaurant_sales_analysis.sql
|-- notebooks
|   `-- restaurant_sales_intelligence_eda.ipynb
|-- outputs
|   |-- charts
|   `-- tables
|-- sql
|   |-- 01_schema.sql
|   |-- 02_cleaning.sql
|   |-- 03_analytics_views.sql
|   `-- 04_business_queries.sql
`-- src
    `-- analysis_pipeline.py
```

## Data Cleaning Summary

- Standardized the raw headers to consistent snake_case.
- Parsed mixed date formats safely:
  - 403 rows used `dd-mm-yyyy`
  - 597 rows used `mm/dd/yyyy`
- Preserved 107 missing `transaction_type` values as `Unknown` rather than fabricating payment labels.
- Validated that `transaction_amount = item_price * quantity` for all rows.
- Confirmed that `order_id` is unique for each row, so the file behaves like a transaction-level fact table.
- Documented `received_by` as a limited categorical label because it only contains `Mr.` and `Mrs.`, which does not support employee-level analysis.

## Methodology

1. Profile the raw CSV and document its quality issues.
2. Clean and enrich the dataset with parsed dates, payment flags, and validation checks.
3. Export a reproducible clean dataset and auditable quality summary.
4. Create reusable SQL scripts for schema setup, cleaning logic, views, and business questions.
5. Generate charts and summary tables for product, time-of-day, payment, and monthly performance.
6. Translate the analysis into business findings and practical recommendations.

## Key Findings

- The dataset contains **$275,230** in revenue across **1,000 orders** and **8,162 units sold**, with an average order value of **$275.23**.
- **Sandwich** is the top revenue product at **$65,820** (23.9% of total revenue), while **Cold coffee** leads unit volume with **1,361 units sold**.
- The top three products by revenue, **Sandwich, Frankie, and Cold coffee**, contribute **64.59%** of total sales.
- **Night** is the strongest daypart with **$62,075** in revenue and the highest average order value at **$302.80**.
- **Fastfood** contributes **68.61%** of revenue and **67.67%** of units sold, making it the dominant category in the current mix.
- Payment capture needs attention: **10.7%** of transactions have missing payment method values.
- Monthly performance is relatively stable from April 2022 through March 2023, but the sharp decline after March 2023 reflects sparse source coverage and should not be treated as confirmed business deterioration.

## Business Recommendations

- Prioritize hero products. Feature Sandwich, Frankie, and Cold coffee in menu placement, bundles, and promotions because they account for most sales.
- Plan staffing and inventory around high-performing dayparts. Night drives the most revenue overall, while beverage sales are strongest in the afternoon.
- Improve payment data capture at checkout. Unknown payment labels affect more than one in ten transactions and reduce trust in payment-mix reporting.
- Avoid performance decisions based on late-2023 monthly declines without confirming whether the source data is complete for those months.

## How to Run the Project

### Python pipeline

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python src/analysis_pipeline.py
```

This command will regenerate:

- `data/processed/restaurant_sales_clean.csv`
- `data/processed/data_quality_issues.csv`
- `outputs/tables/*.csv`
- `outputs/charts/*.png`

### Notebook

Open `notebooks/restaurant_sales_intelligence_eda.ipynb` in Jupyter and run the cells after the pipeline has created the processed outputs.

### SQL

The SQL scripts target MySQL 8.0+. Run them in order:

1. `sql/01_schema.sql`
2. Load `data/raw/restaurant_sales.csv` into `stg_restaurant_sales_raw`
3. `sql/02_cleaning.sql`
4. `sql/03_analytics_views.sql`
5. `sql/04_business_queries.sql`

## Resume-Ready Project Highlights

- Built a reproducible Python and SQL analytics workflow that cleaned and validated 1,000 restaurant transactions with mixed date formats and missing payment data.
- Translated raw sales records into portfolio-ready business outputs including KPI tables, trend charts, SQL views, and an executive summary.
- Produced a documented analytics case study that demonstrates data cleaning, exploratory analysis, business insight generation, and honest communication of data limitations.

## Data Limitations

- The dataset does not include costs, margins, customer identifiers, or store locations, so profitability and customer segmentation cannot be measured directly.
- `received_by` appears to be a title or category label rather than a real staff identifier.
- `transaction_type` is missing for 107 rows.
- Late-2023 data is sparse, so trend conclusions after March 2023 should be treated carefully.

## Future Improvements

- Add cost and margin data to measure gross profit instead of revenue alone.
- Add hourly timestamps or store locations to support staffing and branch-level optimization.
- Build a dashboard layer in Power BI or Tableau on top of the cleaned outputs.
- Extend the model with customer-level data for repeat purchase and basket analysis.
