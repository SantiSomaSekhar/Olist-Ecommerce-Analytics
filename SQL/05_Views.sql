USE olist_ecommerce;

-- 1. Executive Fact View (Orders, Customers, Items, Shipping & Reviews)
CREATE OR REPLACE VIEW vw_olist_executive_fact AS
SELECT 
    o.order_id,
    o.order_status,
    DATE(o.order_purchase_timestamp) AS order_date,
    o.day_type,
    o.shipping_days,
    o.delivery_status,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COALESCE(p.product_category_name, 'Uncategorized') AS category,
    oi.price,
    oi.freight_value,
    (oi.price + oi.freight_value) AS total_item_value,
    r.review_score
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
JOIN olist_products_dataset p ON oi.product_id = p.product_id
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id;

-- 2. Monthly KPI Trend View
CREATE OR REPLACE VIEW vw_monthly_kpis AS
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS active_customers,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gross_revenue,
    ROUND(AVG(o.shipping_days), 2) AS avg_shipping_days
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY order_month;

-- 3. Payment Summary View
CREATE OR REPLACE VIEW vw_payment_summary AS
SELECT 
    payment_type,
    COUNT(order_id) AS total_transactions,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_installments), 1) AS avg_installments
FROM olist_order_payments_dataset
WHERE payment_type != 'not_defined'
GROUP BY payment_type;

-- 4. Product Category Performance View
CREATE OR REPLACE VIEW vw_category_performance AS
SELECT 
    COALESCE(p.product_category_name, 'Uncategorized') AS category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS units_sold,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
LEFT JOIN olist_order_reviews_dataset r ON oi.order_id = r.order_id
GROUP BY category_name;

-- 5. Regional State Performance View (Enriched with Geolocation Coordinates)
CREATE OR REPLACE VIEW vw_state_performance AS
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_cost,
    ROUND(AVG(o.shipping_days), 2) AS avg_shipping_days
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state;

-- 6. Seller Scorecard View
CREATE OR REPLACE VIEW vw_seller_scorecard AS
SELECT 
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi ON s.seller_id = oi.seller_id
LEFT JOIN olist_order_reviews_dataset r ON oi.order_id = r.order_id
GROUP BY s.seller_id, s.seller_city, s.seller_state;