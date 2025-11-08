-- Example: list untagged line items (replace tag keys with your mapping)
SELECT line_item_resource_id, product_product_name, line_item_usage_account_id, SUM(COALESCE(blended_cost, line_item_unblended_cost)) AS cost_usd
FROM cur_db.cur_table
WHERE (resource_tags__owner IS NULL OR resource_tags__app IS NULL OR resource_tags__env IS NULL)
  AND bill_billing_period_start_date >= date_trunc('month', current_date)
GROUP BY 1,2,3
ORDER BY cost_usd DESC
LIMIT 100;
