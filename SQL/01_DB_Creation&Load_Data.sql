-- =========================================================================
-- LEVEL 1: STANDALONE PARENT & LOOKUP TABLES (Create these first)
-- =========================================================================
CREATE DATABASE Olist_Ecommerce;

-- 1. Geolocation Table (Referenced by Customers and Sellers via zip_code_prefix)
CREATE TABLE olist_geolocation_dataset (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(20, 16),
    geolocation_lng DECIMAL(20, 16),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(5),
    PRIMARY KEY (geolocation_zip_code_prefix)
);

-- 2. Products Table (Referenced by Order Items via product_id)
CREATE TABLE olist_products_dataset (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g DECIMAL(10, 2),
    product_length_cm DECIMAL(10, 2),
    product_height_cm DECIMAL(10, 2),
    product_width_cm DECIMAL(10, 2),
    PRIMARY KEY (product_id)
);


-- =========================================================================
-- LEVEL 2: LOCATION-DEPENDENT ENTITIES (Depend on Geolocation)
-- =========================================================================

-- 3. Customers Table (Referenced by Orders via customer_id)
CREATE TABLE olist_customers_dataset (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(5),

    PRIMARY KEY (customer_id),
    INDEX idx_customer_zip (customer_zip_code_prefix)
);

-- 4. Sellers Table (Referenced by Order Items via seller_id)
CREATE TABLE olist_sellers_dataset (
    seller_id VARCHAR(50),
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(5),

    PRIMARY KEY (seller_id),
    INDEX idx_seller_zip (seller_zip_code_prefix)
);


-- =========================================================================
-- LEVEL 3: CENTRAL TRANSACTION TABLE (Depends on Customers)
-- =========================================================================

-- 5. Orders Table (Referenced by Items, Payments, and Reviews via order_id)
CREATE TABLE olist_orders_dataset (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    day_type VARCHAR(20),
    shipping_days INT,
    delivery_status VARCHAR(20),

    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES olist_customers_dataset(customer_id)
);


-- =========================================================================
-- LEVEL 4: CHILD TRANSACTION TABLES (Depend on Orders, Products, Sellers)
-- =========================================================================

-- 6. Order Items Table (Composite PK + 3 Foreign Keys)
CREATE TABLE olist_order_items_dataset (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2),

    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES olist_orders_dataset(order_id),
    FOREIGN KEY (product_id) REFERENCES olist_products_dataset(product_id),
    FOREIGN KEY (seller_id) REFERENCES olist_sellers_dataset(seller_id)
);

-- 7. Order Payments Table (Composite PK + 1 Foreign Key)
CREATE TABLE olist_order_payments_dataset (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10, 2),

    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES olist_orders_dataset(order_id)
);

-- 8. Order Reviews Table (Single PK + 1 Foreign Key)
CREATE TABLE olist_order_reviews_dataset (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    shipping_days INT,

    PRIMARY KEY (review_id),
    FOREIGN KEY (order_id) REFERENCES olist_orders_dataset(order_id)
);


--  Reload the CSV cleanly (0 warnings)
LOAD DATA LOCAL INFILE 'C:/Users/Admin/OneDrive/Documents/ONEDRIVE KARNA/OneDrive/SOMA SEKHAR/PROJECT/ECOMMERCE/sql csv files/olist_geolocation.csv'
INTO TABLE olist_geolocation_dataset
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state);

LOAD DATA LOCAL INFILE 'C:/Users/Admin/OneDrive/Documents/ONEDRIVE KARNA/OneDrive/SOMA SEKHAR/PROJECT/ECOMMERCE/sql csv files/olist_products.csv'
INTO TABLE olist_products_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    product_id, 
    @v_category, 
    @v_name_len, 
    @v_desc_len, 
    @v_photos, 
    @v_weight, 
    @v_length, 
    @v_height, 
    @v_width
)
SET 
    product_category_name      = NULLIF(@v_category, ''),
    product_name_lenght        = NULLIF(@v_name_len, ''),
    product_description_lenght = NULLIF(@v_desc_len, ''),
    product_photos_qty         = NULLIF(@v_photos, ''),
    product_weight_g           = NULLIF(@v_weight, ''),
    product_length_cm          = NULLIF(@v_length, ''),
    product_height_cm          = NULLIF(@v_height, ''),
    product_width_cm           = NULLIF(@v_width, '');
    
    LOAD DATA LOCAL INFILE 'C:/Users/Admin/OneDrive/Documents/ONEDRIVE KARNA/OneDrive/SOMA SEKHAR/PROJECT/ECOMMERCE/sql csv files/olist_customers.csv'
INTO TABLE olist_customers_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    customer_id, 
    customer_unique_id, 
    customer_zip_code_prefix, 
    customer_city, 
    customer_state
);

LOAD DATA LOCAL INFILE 'C:/Users/Admin/OneDrive/Documents/ONEDRIVE KARNA/OneDrive/SOMA SEKHAR/PROJECT/ECOMMERCE/sql csv files/olist_sellers.csv'
INTO TABLE olist_sellers_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    seller_id, 
    seller_zip_code_prefix, 
    seller_city, 
    seller_state
);

LOAD DATA LOCAL INFILE 'C:/Users/Admin/OneDrive/Documents/ONEDRIVE KARNA/OneDrive/SOMA SEKHAR/PROJECT/ECOMMERCE/sql csv files/olist_orders.csv'
INTO TABLE olist_orders_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    order_id, 
    customer_id, 
    order_status, 
    order_purchase_timestamp, 
    @v_approved, 
    @v_carrier, 
    @v_customer, 
    order_estimated_delivery_date,
    day_type,
    @v_shipping_days,
    delivery_status
)
SET 
    order_approved_at             = NULLIF(@v_approved, ''),
    order_delivered_carrier_date  = NULLIF(@v_carrier, ''),
    order_delivered_customer_date = NULLIF(@v_customer, ''),
    shipping_days                 = NULLIF(@v_shipping_days, '');
    
    LOAD DATA LOCAL INFILE 'C:/Users/Admin/OneDrive/Documents/ONEDRIVE KARNA/OneDrive/SOMA SEKHAR/PROJECT/ECOMMERCE/sql csv files/olist_order_items.csv'
INTO TABLE olist_order_items_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    order_id, 
    order_item_id, 
    product_id, 
    seller_id, 
    shipping_limit_date, 
    price, 
    freight_value
);

LOAD DATA LOCAL INFILE 'C:/Users/Admin/OneDrive/Documents/ONEDRIVE KARNA/OneDrive/SOMA SEKHAR/PROJECT/ECOMMERCE/sql csv files/olist_order_payments.csv'
INTO TABLE olist_order_payments_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    order_id, 
    payment_sequential, 
    payment_type, 
    payment_installments, 
    payment_value
);

LOAD DATA LOCAL INFILE 'C:/Users/Admin/OneDrive/Documents/ONEDRIVE KARNA/OneDrive/SOMA SEKHAR/PROJECT/ECOMMERCE/sql csv files/olist_order_reviews.csv'
INTO TABLE olist_order_reviews_dataset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    review_id, 
    order_id, 
    review_score, 
    review_comment_title, 
    review_comment_message, 
    review_creation_date, 
    review_answer_timestamp,
    @v_shipping_days
)
SET 
    shipping_days = NULLIF(@v_shipping_days, '');