USE olist_ecommerce;

-- 1. Monthly Revenue, MoM Growth % & Cumulative Running Total
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS monthly_revenue
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY order_month
)
SELECT 
    order_month,
    total_orders,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY order_month) AS prev_month_revenue,
    ROUND((monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY order_month)) * 100.0 /
          NULLIF(LAG(monthly_revenue) OVER (ORDER BY order_month), 0), 2) AS mom_growth_pct,
    SUM(monthly_revenue) OVER (ORDER BY order_month) AS cumulative_revenue
FROM monthly_sales
ORDER BY order_month;

-- 2. 3-Month Moving Average of Order Volume & Revenue
WITH monthly_metrics AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        COUNT(DISTINCT o.order_id) AS orders_count,
        ROUND(SUM(p.payment_value), 2) AS revenue
    FROM olist_orders_dataset o
    JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY order_month
)
SELECT 
    order_month,
    orders_count,
    revenue,
    ROUND(AVG(revenue) OVER (ORDER BY order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3m_revenue
FROM monthly_metrics
ORDER BY order_month;

-- 3. Top 3 Sellers per State Ranked by Revenue using DENSE_RANK()
WITH seller_state_sales AS (
    SELECT 
        s.seller_state,
        s.seller_id,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        ROUND(SUM(oi.price), 2) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY s.seller_state ORDER BY SUM(oi.price) DESC) AS state_rank
    FROM olist_order_items_dataset oi
    JOIN olist_sellers_dataset s ON oi.seller_id = s.seller_id
    JOIN olist_orders_dataset o ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_state, s.seller_id
)
SELECT * 
FROM seller_state_sales
WHERE state_rank <= 3
ORDER BY seller_state, state_rank;

-- 4. Pareto (80/20) Revenue Contribution by Product Category
WITH category_rev AS (
    SELECT 
        COALESCE(p.product_category_name, 'Uncategorized') AS category,
        ROUND(SUM(oi.price), 2) AS revenue
    FROM olist_order_items_dataset oi
    JOIN olist_products_dataset p ON oi.product_id = p.product_id
    GROUP BY category
)
SELECT 
    category,
    revenue,
    ROUND(SUM(revenue) OVER (ORDER BY revenue DESC) * 100.0 / SUM(revenue) OVER(), 2) AS cumulative_rev_pct
FROM category_rev
ORDER BY revenue DESC
LIMIT 20;

-- 5. Customer Retention & Repeat Purchase Segmentation
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count,
        ROUND(SUM(p.payment_value), 2) AS lifetime_spend
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-Time Buyer'
        WHEN order_count = 2 THEN '2x Repeat Buyer'
        ELSE 'Loyal Buyer (3+ Orders)'
    END AS customer_segment,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS customer_share_pct,
    ROUND(AVG(lifetime_spend), 2) AS avg_clv
FROM customer_orders
GROUP BY customer_segment;

-- 6. RFM (Recency, Frequency, Monetary) Customer Scoring with NTILE()
WITH rfm_base AS (
    SELECT 
        c.customer_unique_id,
        DATEDIFF((SELECT MAX(order_purchase_timestamp) FROM olist_orders_dataset), MAX(o.order_purchase_timestamp)) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(p.payment_value), 2) AS monetary
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT 
    CONCAT(r_score, f_score, m_score) AS rfm_cell,
    COUNT(*) AS customer_count,
    ROUND(AVG(monetary), 2) AS avg_monetary_value
FROM rfm_scores
GROUP BY rfm_cell
ORDER BY avg_monetary_value DESC
LIMIT 10;

-- 7. Average Time Gap Between First and Second Purchase (Repeat Buyers)
WITH ranked_orders AS (
    SELECT 
        c.customer_unique_id,
        o.order_purchase_timestamp,
        ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) AS order_seq,
        LAG(o.order_purchase_timestamp) OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) AS prev_order_date
    FROM olist_customers_dataset c
    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
)
SELECT 
    ROUND(AVG(DATEDIFF(order_purchase_timestamp, prev_order_date)), 1) AS avg_days_to_repeat_purchase,
    MIN(DATEDIFF(order_purchase_timestamp, prev_order_date)) AS min_days,
    MAX(DATEDIFF(order_purchase_timestamp, prev_order_date)) AS max_days
FROM ranked_orders
WHERE order_seq = 2;