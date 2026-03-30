-- Restaurant Sales Intelligence
-- Business questions answered directly from the cleaned fact table and views.
-- Note: profitability cannot be measured exactly because the dataset does not include cost or margin data.
-- Revenue contribution is used as a practical proxy where needed, and that limitation should be stated in reporting.

USE restaurant_sales_portfolio;

-- 1. Core KPIs: total sales, total orders, average order value, and total quantity sold.
SELECT *
FROM vw_kpi_summary;

-- 2. Which items drive the most revenue?
SELECT
    item_name,
    item_type,
    revenue,
    quantity_sold,
    orders,
    average_order_value
FROM vw_item_performance
ORDER BY revenue DESC;

-- 3. Which items sell the most by volume?
SELECT
    item_name,
    item_type,
    quantity_sold,
    revenue,
    orders
FROM vw_item_performance
ORDER BY quantity_sold DESC;

-- 4. Which time_of_sale periods generate the most sales?
SELECT
    time_of_sale,
    orders,
    quantity_sold,
    revenue,
    average_order_value
FROM vw_time_of_sale_performance
ORDER BY revenue DESC;

-- 5. What is the monthly sales trend?
SELECT
    order_month,
    orders,
    quantity_sold,
    revenue,
    average_order_value
FROM vw_monthly_sales
ORDER BY order_month;

-- 6. Which payment methods are most common?
SELECT
    transaction_type,
    orders,
    quantity_sold,
    revenue,
    average_order_value
FROM vw_payment_mix
ORDER BY orders DESC;

-- 7. Are beverages or fast food stronger on revenue and quantity?
-- This is not a true profitability query because costs are unavailable.
SELECT
    item_type,
    orders,
    quantity_sold,
    revenue,
    ROUND(revenue / SUM(revenue) OVER () * 100, 2) AS revenue_share_pct,
    ROUND(quantity_sold / SUM(quantity_sold) OVER () * 100, 2) AS quantity_share_pct
FROM vw_item_type_mix
ORDER BY revenue DESC;

-- 8. Which combinations of item type and time_of_sale perform best?
SELECT
    item_type,
    time_of_sale,
    orders,
    quantity_sold,
    revenue,
    average_order_value
FROM vw_item_type_time_of_sale
ORDER BY revenue DESC;

-- 9. Where is payment capture weakest?
SELECT
    order_month,
    COUNT(*) AS total_orders,
    SUM(payment_missing_flag) AS unknown_payment_orders,
    ROUND(SUM(payment_missing_flag) / COUNT(*) * 100, 2) AS unknown_payment_share_pct
FROM fact_restaurant_sales
GROUP BY order_month
ORDER BY unknown_payment_share_pct DESC, total_orders DESC;

-- 10. Which products have both strong demand and strong basket value?
SELECT
    item_name,
    item_type,
    COUNT(*) AS orders,
    SUM(quantity) AS quantity_sold,
    ROUND(SUM(transaction_amount), 2) AS revenue,
    ROUND(AVG(transaction_amount), 2) AS average_order_value
FROM fact_restaurant_sales
GROUP BY item_name, item_type
HAVING SUM(transaction_amount) >= (
    SELECT AVG(revenue)
    FROM vw_item_performance
)
ORDER BY revenue DESC, average_order_value DESC;

-- 11. Data quality checks that should be reviewed alongside business results.
SELECT *
FROM vw_data_quality_audit;
