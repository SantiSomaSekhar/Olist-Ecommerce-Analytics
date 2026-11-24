USE olist_ecommerce;

-- 1. Executive KPI Summary (Total Orders, Revenue, AOV, Shipping Days & Review Score)
SELECT 
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    ROUND(SUM(p.payment_value), 2) AS total_revenue,
    ROUND(SUM(p.payment_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
    ROUND(AVG(o.shipping_days), 2) AS avg_shipping_days,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
LEFT JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered';

-- 2. Payment Method Share & Installment Behavior (Credit Card Dominance ~78%)
SELECT 
    payment_type,
    COUNT(order_id) AS total_transactions,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(COUNT(order_id) * 100.0 / SUM(COUNT(order_id)) OVER(), 2) AS transaction_share_pct,
    ROUND(AVG(payment_installments), 1) AS avg_installments
FROM olist_order_payments_dataset
WHERE payment_type != 'not_defined'
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- 3. Impact of Delivery Status on Customer Review Scores (Using Pre-Engineered Columns)
SELECT 
    o.delivery_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(COUNT(DISTINCT o.order_id) * 100.0 / SUM(COUNT(DISTINCT o.order_id)) OVER(), 2) AS order_share_pct,
    ROUND(AVG(o.shipping_days), 2) AS avg_shipping_days,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olist_orders_dataset o
JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.delivery_status IS NOT NULL
GROUP BY o.delivery_status;

-- 4. Weekday vs. Weekend Sales & Order Behavior (Using Pre-Engineered day_type)
SELECT 
    o.day_type,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value), 2) AS total_revenue,
    ROUND(AVG(p.payment_value), 2) AS avg_order_value,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY o.day_type;

-- 5. Top 10 Product Categories by Revenue
SELECT 
    COALESCE(p.product_category_name, 'Uncategorized') AS category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS units_sold,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(AVG(oi.price), 2) AS avg_item_price,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
LEFT JOIN olist_order_reviews_dataset r ON oi.order_id = r.order_id
GROUP BY category_name
ORDER BY product_revenue DESC
LIMIT 10;

-- 6. State-wise Sales, Freight Cost & Shipping Duration
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_cost,
    ROUND(AVG(o.shipping_days), 2) AS avg_shipping_days,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_sales DESC
LIMIT 10;

-- 7. Peak Shopping Hours of the Day
SELECT 
    HOUR(order_purchase_timestamp) AS order_hour,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(COUNT(DISTINCT order_id) * 100.0 / SUM(COUNT(DISTINCT order_id)) OVER(), 2) AS order_share_pct
FROM olist_orders_dataset
GROUP BY order_hour
ORDER BY total_orders DESC;

-- 8. Freight-to-Price Ratio by Product Category (Top 10 Highest Shipping Burden)
SELECT 
    COALESCE(p.product_category_name, 'Uncategorized') AS category_name,
    ROUND(AVG(oi.price), 2) AS avg_price,
    ROUND(AVG(oi.freight_value), 2) AS avg_freight,
    ROUND(SUM(oi.freight_value) * 100.0 / SUM(oi.price), 2) AS freight_to_price_pct
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
GROUP BY category_name
HAVING COUNT(*) >= 100
ORDER BY freight_to_price_pct DESC
LIMIT 10;