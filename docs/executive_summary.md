# Executive Summary

## Key Findings

1. The source data captures **1,000 restaurant transactions** from **January 4, 2022 to December 3, 2023**, totaling **$275,230** in revenue and **8,162 units sold**.
2. Average order value is **$275.23**, and average units per order are **8.16**, indicating that customers typically purchase multiple units per transaction.
3. **Sandwich** is the largest revenue contributor at **$65,820**, while **Cold coffee** is the highest-volume item at **1,361 units sold**.
4. The top three revenue drivers, **Sandwich, Frankie, and Cold coffee**, account for **64.59%** of total revenue, showing a concentrated sales mix.
5. **Night** is the strongest sales period with **$62,075** in revenue and the highest average order value at **$302.80**.
6. **Fastfood** contributes **68.61%** of total revenue and **67.67%** of unit volume, making it the dominant category relative to beverages.
7. Payment reporting has a material quality gap: **107 transactions (10.7%)** have missing `transaction_type` values.
8. Revenue trends are fairly stable through most of 2022 and early 2023, but late-2023 activity is sparse in the source data, so the apparent decline should be treated as incomplete coverage rather than confirmed performance drop-off.

## Business Recommendations

1. Push the top-performing items harder. Use Sandwich, Frankie, and Cold coffee in bundles, featured placements, and targeted promotions.
2. Align staffing and inventory to demand. Prioritize night operations overall and afternoon beverage readiness because those windows show the strongest sales concentration.
3. Fix payment capture at the source. Reducing unknown payment values will improve reporting reliability for channel and checkout analysis.
4. Treat late-2023 trend analysis cautiously until source completeness is confirmed.

## Resume-Style Impact Statements

- Built a reproducible restaurant sales analysis pipeline in Python and SQL that cleaned mixed-format transaction data and generated portfolio-ready outputs.
- Produced executive-level business insights on product mix, daypart performance, and revenue concentration using 1,000 real restaurant transactions.
- Documented data quality limitations transparently, including mixed date formats, missing payment values, and an ambiguous staff-related field.
