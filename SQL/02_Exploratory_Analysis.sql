USE olist_ecommerce;

-- 1. Table Row Count Audit (All 8 Tables)
SELECT 'olist_customers_dataset' AS table_name, COUNT(*) AS row_count FROM olist_customers_dataset
UNION ALL SELECT 'olist_geolocation_dataset', COUNT(*) FROM olist_geolocation_dataset
UNION ALL SELECT 'olist_orders_dataset', COUNT(*) FROM olist_orders_dataset
UNION ALL SELECT 'olist_order_items_dataset', COUNT(*) FROM olist_order_items_dataset
UNION ALL SELECT 'olist_order_payments_dataset', COUNT(*) FROM olist_order_payments_dataset
UNION ALL SELECT 'olist_order_reviews_dataset', COUNT(*) FROM olist_order_reviews_dataset
UNION ALL SELECT 'olist_products_dataset', COUNT(*) FROM olist_products_dataset
UNION ALL SELECT 'olist_sellers_dataset', COUNT(*) FROM olist_sellers_dataset;

-- 2. Order Status Breakdown & Percentage Share
SELECT 
    order_status,
    COUNT(*) AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS share_pct
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY total_orders DESC;

-- 3. Dataset Time Span & Active Operating Days
SELECT 
    MIN(order_purchase_timestamp) AS earliest_order,
    MAX(order_purchase_timestamp) AS latest_order,
    DATEDIFF(MAX(order_purchase_timestamp), MIN(order_purchase_timestamp)) AS total_span_days,
    COUNT(DISTINCT DATE(order_purchase_timestamp)) AS active_order_days
FROM olist_orders_dataset;

-- 4. Review Score Distribution (1 to 5 Stars)
SELECT 
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS share_pct
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score DESC;

-- 5. Geographic Footprint (Customers, Sellers & Geolocation Zip Codes)
SELECT 
    (SELECT COUNT(DISTINCT customer_state) FROM olist_customers_dataset) AS customer_states,
    (SELECT COUNT(DISTINCT customer_city) FROM olist_customers_dataset) AS customer_cities,
    (SELECT COUNT(DISTINCT seller_state) FROM olist_sellers_dataset) AS seller_states,
    (SELECT COUNT(DISTINCT seller_city) FROM olist_sellers_dataset) AS seller_cities,
    (SELECT COUNT(DISTINCT geolocation_zip_code_prefix) FROM olist_geolocation_dataset) AS total_zip_prefixes;

-- 6. Product Catalog & Category Coverage
SELECT 
    COUNT(DISTINCT product_id) AS total_products,
    COUNT(DISTINCT product_category_name) AS total_categories,
    SUM(CASE WHEN product_category_name IS NULL OR product_category_name = '' THEN 1 ELSE 0 END) AS uncategorized_products
FROM olist_products_dataset;

-- 7. Order Item & Basket Size Distribution
SELECT 
    items_per_order,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS order_share_pct
FROM (
    SELECT order_id, COUNT(order_item_id) AS items_per_order
    FROM olist_order_items_dataset
    GROUP BY order_id
) t
GROUP BY items_per_order
ORDER BY items_per_order
LIMIT 10;