USE olist_ecommerce;

-- 1. Duplicate Primary Key Checks
SELECT 'orders_duplicates' AS check_name, COUNT(*) AS issue_count
FROM (SELECT order_id FROM olist_orders_dataset GROUP BY order_id HAVING COUNT(*) > 1) t
UNION ALL
SELECT 'customers_duplicates', COUNT(*)
FROM (SELECT customer_id FROM olist_customers_dataset GROUP BY customer_id HAVING COUNT(*) > 1) t
UNION ALL
SELECT 'products_duplicates', COUNT(*)
FROM (SELECT product_id FROM olist_products_dataset GROUP BY product_id HAVING COUNT(*) > 1) t;

-- 2. NULL Delivery Timestamp Check for Delivered Orders
SELECT COUNT(*) AS delivered_without_timestamp
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- 3. Negative or Zero Price & Freight Check
SELECT COUNT(*) AS invalid_price_or_freight
FROM olist_order_items_dataset
WHERE price <= 0 OR freight_value < 0;

-- 4. Invalid Chronological Date Sequence Check (Delivered Before Purchase)
SELECT COUNT(*) AS invalid_delivery_dates
FROM olist_orders_dataset
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- 5. Review Score Range Check (Must Be Between 1 and 5)
SELECT COUNT(*) AS out_of_range_reviews
FROM olist_order_reviews_dataset
WHERE review_score NOT BETWEEN 1 AND 5;

-- 6. Orphan Record Check (Orders Missing Payment Entries)
SELECT COUNT(o.order_id) AS orders_without_payments
FROM olist_orders_dataset o
LEFT JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
WHERE p.order_id IS NULL;