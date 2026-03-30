-- Restaurant Sales Intelligence
-- SQL dialect: MySQL 8.0+
--
-- Design notes:
-- 1. The source CSV behaves like a transaction fact table because each order_id is unique.
-- 2. No separate Payment or Staff table is created because the raw file does not support those relationships.
-- 3. received_by is stored only as a label because values such as 'Mr.' and 'Mrs.' do not identify real employees.

CREATE SCHEMA IF NOT EXISTS restaurant_sales_portfolio;
USE restaurant_sales_portfolio;

DROP TABLE IF EXISTS fact_restaurant_sales;
DROP TABLE IF EXISTS stg_restaurant_sales_raw;

CREATE TABLE stg_restaurant_sales_raw (
    order_id INT PRIMARY KEY,
    date_raw VARCHAR(20) NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    item_type VARCHAR(50) NOT NULL,
    item_price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    transaction_amount DECIMAL(10, 2) NOT NULL,
    transaction_type VARCHAR(20) NULL,
    received_by VARCHAR(20) NOT NULL,
    time_of_sale VARCHAR(20) NOT NULL
);

CREATE TABLE fact_restaurant_sales (
    order_id INT PRIMARY KEY,
    order_date DATE NULL,
    order_year SMALLINT NULL,
    order_month CHAR(7) NULL,
    order_month_start DATE NULL,
    order_day_name VARCHAR(15) NULL,
    item_name VARCHAR(100) NOT NULL,
    item_type VARCHAR(50) NOT NULL,
    item_price DECIMAL(10, 2) NOT NULL,
    quantity INT NOT NULL,
    transaction_amount DECIMAL(10, 2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    payment_missing_flag BOOLEAN NOT NULL,
    received_by_label VARCHAR(20) NOT NULL,
    received_by_is_ambiguous BOOLEAN NOT NULL,
    time_of_sale VARCHAR(20) NOT NULL,
    date_format_source VARCHAR(20) NOT NULL,
    amount_matches_expected BOOLEAN NOT NULL
);

CREATE INDEX idx_fact_order_date ON fact_restaurant_sales (order_date);
CREATE INDEX idx_fact_order_month ON fact_restaurant_sales (order_month);
CREATE INDEX idx_fact_item_name ON fact_restaurant_sales (item_name);
CREATE INDEX idx_fact_item_type ON fact_restaurant_sales (item_type);
CREATE INDEX idx_fact_time_of_sale ON fact_restaurant_sales (time_of_sale);
CREATE INDEX idx_fact_transaction_type ON fact_restaurant_sales (transaction_type);

-- Example import step once the schema exists:
-- LOAD DATA LOCAL INFILE 'path/to/data/raw/restaurant_sales.csv'
-- INTO TABLE stg_restaurant_sales_raw
-- FIELDS TERMINATED BY ','
-- OPTIONALLY ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS
-- (order_id, date_raw, item_name, item_type, item_price, quantity,
--  transaction_amount, transaction_type, received_by, time_of_sale);

