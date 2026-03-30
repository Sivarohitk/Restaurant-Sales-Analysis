-- Restaurant Sales Intelligence
-- Transform staged raw rows into an analytics-friendly fact table.
-- Assumptions:
-- 1. date_raw uses either dd-mm-yyyy or mm/dd/yyyy.
-- 2. Missing transaction_type values are preserved as 'Unknown' rather than imputed.
-- 3. received_by is a category label, not a staff dimension.

USE restaurant_sales_portfolio;

DELETE FROM fact_restaurant_sales;

WITH typed_source AS (
    SELECT
        order_id,
        TRIM(date_raw) AS date_raw,
        TRIM(item_name) AS item_name,
        TRIM(item_type) AS item_type,
        item_price,
        quantity,
        transaction_amount,
        CASE
            WHEN transaction_type IS NULL OR TRIM(transaction_type) = '' THEN 'Unknown'
            ELSE TRIM(transaction_type)
        END AS transaction_type_clean,
        CASE
            WHEN transaction_type IS NULL OR TRIM(transaction_type) = '' THEN TRUE
            ELSE FALSE
        END AS payment_missing_flag,
        TRIM(received_by) AS received_by_label,
        CASE
            WHEN TRIM(received_by) IN ('Mr.', 'Mrs.') THEN TRUE
            ELSE FALSE
        END AS received_by_is_ambiguous,
        TRIM(time_of_sale) AS time_of_sale,
        CASE
            WHEN date_raw LIKE '%-%' THEN STR_TO_DATE(date_raw, '%d-%m-%Y')
            WHEN date_raw LIKE '%/%' THEN STR_TO_DATE(date_raw, '%m/%d/%Y')
            ELSE NULL
        END AS order_date,
        CASE
            WHEN date_raw LIKE '%-%' THEN 'dd-mm-yyyy'
            WHEN date_raw LIKE '%/%' THEN 'mm/dd/yyyy'
            ELSE 'unknown'
        END AS date_format_source,
        CASE
            WHEN item_price * quantity = transaction_amount THEN TRUE
            ELSE FALSE
        END AS amount_matches_expected
    FROM stg_restaurant_sales_raw
)
INSERT INTO fact_restaurant_sales (
    order_id,
    order_date,
    order_year,
    order_month,
    order_month_start,
    order_day_name,
    item_name,
    item_type,
    item_price,
    quantity,
    transaction_amount,
    transaction_type,
    payment_missing_flag,
    received_by_label,
    received_by_is_ambiguous,
    time_of_sale,
    date_format_source,
    amount_matches_expected
)
SELECT
    order_id,
    order_date,
    YEAR(order_date) AS order_year,
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    CAST(DATE_FORMAT(order_date, '%Y-%m-01') AS DATE) AS order_month_start,
    DAYNAME(order_date) AS order_day_name,
    item_name,
    item_type,
    item_price,
    quantity,
    transaction_amount,
    transaction_type_clean,
    payment_missing_flag,
    received_by_label,
    received_by_is_ambiguous,
    time_of_sale,
    date_format_source,
    amount_matches_expected
FROM typed_source;

