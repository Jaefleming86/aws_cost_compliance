-- Show top AWS services spend for current month (Athena; CUR view/table required)
SELECT line_item_product_code AS service,
       SUM(COALESCE(blended_cost, line_item_unblended_cost)) AS spend_usd
FROM cur_db.cur_table
WHERE bill_billing_period_start_date >= date_trunc('month', current_date)
GROUP BY 1
ORDER BY spend_usd DESC
LIMIT 10;
