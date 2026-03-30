-- Restaurant Sales Intelligence
-- Reusable analytical views for KPI tracking and exploratory analysis.

USE restaurant_sales_portfolio;

CREATE OR REPLACE VIEW vw_kpi_summary AS
SELECT
    ROUND(SUM(transaction_amount), 2) AS total_sales,
    COUNT(*) AS total_orders,
    ROUND(AVG(transaction_amount), 2) AS average_order_value,
    SUM(quantity) AS total_quantity_sold,
    ROUND(SUM(payment_missing_flag) / COUNT(*) * 100, 2) AS missing_payment_share_pct
FROM fact_restaurant_sales;

CREATE OR REPLACE VIEW vw_item_performance AS
SELECT
    item_name,
    item_type,
    COUNT(*) AS orders,
    SUM(quantity) AS quantity_sold,
    ROUND(SUM(transaction_amount), 2) AS revenue,
    ROUND(AVG(transaction_amount), 2) AS average_order_value
FROM fact_restaurant_sales
GROUP BY item_name, item_type;

CREATE OR REPLACE VIEW vw_monthly_sales AS
SELECT
    order_month,
    COUNT(*) AS orders,
    SUM(quantity) AS quantity_sold,
    ROUND(SUM(transaction_amount), 2) AS revenue,
    ROUND(AVG(transaction_amount), 2) AS average_order_value
FROM fact_restaurant_sales
GROUP BY order_month;

CREATE OR REPLACE VIEW vw_time_of_sale_performance AS
SELECT
    time_of_sale,
    COUNT(*) AS orders,
    SUM(quantity) AS quantity_sold,
    ROUND(SUM(transaction_amount), 2) AS revenue,
    ROUND(AVG(transaction_amount), 2) AS average_order_value
FROM fact_restaurant_sales
GROUP BY time_of_sale;

CREATE OR REPLACE VIEW vw_payment_mix AS
SELECT
    transaction_type,
    COUNT(*) AS orders,
    SUM(quantity) AS quantity_sold,
    ROUND(SUM(transaction_amount), 2) AS revenue,
    ROUND(AVG(transaction_amount), 2) AS average_order_value
FROM fact_restaurant_sales
GROUP BY transaction_type;

CREATE OR REPLACE VIEW vw_item_type_mix AS
SELECT
    item_type,
    COUNT(*) AS orders,
    SUM(quantity) AS quantity_sold,
    ROUND(SUM(transaction_amount), 2) AS revenue
FROM fact_restaurant_sales
GROUP BY item_type;

CREATE OR REPLACE VIEW vw_item_type_time_of_sale AS
SELECT
    item_type,
    time_of_sale,
    COUNT(*) AS orders,
    SUM(quantity) AS quantity_sold,
    ROUND(SUM(transaction_amount), 2) AS revenue,
    ROUND(AVG(transaction_amount), 2) AS average_order_value
FROM fact_restaurant_sales
GROUP BY item_type, time_of_sale;

CREATE OR REPLACE VIEW vw_data_quality_audit AS
SELECT
    'missing_transaction_type' AS issue_type,
    SUM(payment_missing_flag) AS affected_rows
FROM fact_restaurant_sales
UNION ALL
SELECT
    'transaction_amount_mismatch' AS issue_type,
    SUM(CASE WHEN amount_matches_expected = FALSE THEN 1 ELSE 0 END) AS affected_rows
FROM fact_restaurant_sales
UNION ALL
SELECT
    'received_by_field_limitation' AS issue_type,
    SUM(received_by_is_ambiguous) AS affected_rows
FROM fact_restaurant_sales
UNION ALL
SELECT
    'unparsed_dates' AS issue_type,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS affected_rows
FROM fact_restaurant_sales;

