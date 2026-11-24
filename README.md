# 🛒 Olist E-Commerce End-to-End Analytics

![MySQL](https://img.shields.io/badge/MySQL-8.0+-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Tableau](https://img.shields.io/badge/Tableau-E97627?style=for-the-badge&logo=tableau&logoColor=white)
![Excel](https://img.shields.io/badge/Microsoft_Excel-217346?style=for-the-badge&logo=microsoft-excel&logoColor=white)

## 📌 Project Overview

An end-to-end business intelligence and relational data analytics project analyzing the **Olist Brazilian E-Commerce** dataset. The workflow spans data cleaning, feature engineering, normalized 8-table relational database design in **MySQL**, business KPI querying, and interactive multi-tool dashboards across **Power BI**, **Tableau**, and **Microsoft Excel**.

### 🎯 Key Business Objectives
* **Logistics & Delivery Efficiency:** Measure actual shipping duration (`11.31 days` average delivery benchmark) and evaluate how delivery timeliness (`On-Time` vs. `Delayed`) impacts customer satisfaction scores.
* **Payment & Customer Behavior:** Analyze payment method preferences (credit card share and installment trends), weekday vs. weekend purchasing patterns, and repeat buyer retention.
* **Product & Regional Performance:** Identify top revenue-generating product categories, high freight-burden items, and state-level sales and fulfillment bottlenecks.

---

## 🗄️ Database Architecture (`olist_ecommerce`)

The dataset is structured into a normalized **8-table relational schema** in MySQL (`DB_Creation&Load_Data.sql`) with Primary Keys, Composite Keys, Indexes, and Foreign Key constraints across four hierarchical levels:

| Level | Table Name | Primary Key | Key Relationships & Engineered Fields |
| :--- | :--- | :--- | :--- |
| **Level 1 (Lookup)** | `olist_geolocation_dataset` | `geolocation_zip_code_prefix` | Geographic coordinates (`lat`, `lng`), city, and state |
| **Level 1 (Lookup)** | `olist_products_dataset` | `product_id` | Cleaned product categories, dimensions, weight, and photo counts |
| **Level 2 (Entity)** | `olist_customers_dataset` | `customer_id` | Indexed on `customer_zip_code_prefix`; tracks `customer_unique_id` |
| **Level 2 (Entity)** | `olist_sellers_dataset` | `seller_id` | Indexed on `seller_zip_code_prefix`; seller city and state |
| **Level 3 (Fact)** | `olist_orders_dataset` | `order_id` | FK to `customers`; includes engineered `day_type`, `shipping_days`, `delivery_status` |
| **Level 4 (Child)** | `olist_order_items_dataset` | `(order_id, order_item_id)` | Composite PK; FKs to `orders`, `products`, and `sellers` |
| **Level 4 (Child)** | `olist_order_payments_dataset` | `(order_id, payment_sequential)` | Composite PK; FK to `orders`; tracks payment type & installments |
| **Level 4 (Child)** | `olist_order_reviews_dataset` | `review_id` | FK to `orders`; tracks 1–5 star ratings, comments, and `shipping_days` |

---

## 📂 Repository Structure

```text
Olist-Ecommerce-Analytics/
├── 📁 sql/
│   ├── 01_DB_Creation&Load_Data.sql    # 8-table DDL schema, constraints & LOAD DATA INFILE scripts
│   ├── 02_exploratory_analysis.sql     # Row audits, order status shares, date spans & basket sizes
│   ├── 03_business_questions.sql       # Core KPIs: delivery vs. reviews, payments, categories & states
│   ├── 04_advanced_sql.sql             # CTEs, MoM growth, 3M moving averages, Pareto & RFM scoring
│   ├── 05_views.sql                    # 6 reporting views built for Power BI & Tableau consumption
│   ├── 06_validation.sql               # Duplicate PK, NULL timestamp & business rule integrity checks
│   └── 07_stored_procedures.sql        # 5 parameterized procedures for state, seller & date filtering
├── 📁 powerbi/                         # Power BI (.pbix) interactive dashboard & theme files
├── 📁 tableau/                         # Tableau (.twbx) workbook & visual sheets
├── 📁 excel/                           # Cleaned datasets, PivotTables & KPI summary workbook
├── 📁 presentation/                    # Executive project presentation deck (.pptx / .pdf)
├── 📁 assets/                          # Dashboard screenshots & ER diagram
└── README.md
```

## 🧠 SQL Analysis & Technical Highlights

### 🔹 Database Engineering & Data Loading (`01_DB_Creation&Load_Data.sql`)
* Enforced referential integrity across 8 tables using single and composite primary keys alongside foreign key constraints.
* Handled blank string conversions cleanly during bulk CSV ingestion using `LOAD DATA LOCAL INFILE`, `@user_variables`, and `NULLIF()`.

### 🔹 Core Business & Exploratory Queries (`02` & `03`)
* **Executive KPI Scorecard:** Consolidated total delivered orders, unique customers, gross revenue, Average Order Value (AOV), average shipping days, and review ratings.
* **Delivery vs. Review Correlation:** Segmented `On-Time` vs. `Delayed` orders to quantify the drop in average review scores caused by late deliveries.
* **Payment & Timing Insights:** Analyzed installment adoption across payment types and compared `Weekday` vs. `Weekend` ordering volume.

### 🔹 Advanced SQL (`04_advanced_sql.sql`)
* **Time-Series & Window Functions:** Computed Month-over-Month (MoM) revenue growth using `LAG()`, cumulative running totals with `SUM() OVER()`, and 3-month rolling averages (`ROWS BETWEEN 2 PRECEDING AND CURRENT ROW`).
* **Ranking & Pareto Analysis:** Ranked top 3 sellers per state with `DENSE_RANK()` and calculated cumulative 80/20 revenue contribution across product categories.
* **Customer Segmentation & RFM:** Built `NTILE(4)` Recency-Frequency-Monetary customer scoring and measured repeat purchase intervals using `ROW_NUMBER()`.

### 🔹 BI Views, Validation & Stored Procedures (`05`, `06` & `07`)
* Created 6 reusable SQL views (`vw_olist_executive_fact`, `vw_monthly_kpis`, `vw_payment_summary`, `vw_category_performance`, `vw_state_performance`, `vw_seller_scorecard`) for direct BI ingestion.
* Automated data quality audits (duplicate keys, chronological date sequence checks, and orphan payment checks) and built 5 parameterized stored procedures (`sp_GetStatePerformance`, `sp_GetTopCategories`, `sp_GetDateRangeSummary`, `sp_GetSellerProfile`, `sp_GetPaymentsByOrderStatus`).

---

## 📊 Dashboards & Visualizations

* **Power BI Dashboard:** Interactive multi-page executive report featuring DAX time-intelligence measures, dynamic KPI cards, state-level maps, and drillthrough views.
* **Tableau Workbook:** Visual exploration of shipping duration vs. review scores, category revenue breakdowns, and payment method distributions.
* **Microsoft Excel:** Data cleaning pipeline, PivotTable summaries, and executive KPI tracking.

---

## 🚀 How to Reproduce

1. **Clone the Repository:**
   ```bash
   git clone [https://github.com/SantiSomaSekhar/Olist-Ecommerce-Analytics.git](https://github.com/SantiSomaSekhar/Olist-Ecommerce-Analytics.git)
   ```
   1. **Set Up the MySQL Database:**
   * Open MySQL Workbench and run `sql/01_DB_Creation&Load_Data.sql` (update the local CSV file paths in `LOAD DATA LOCAL INFILE` to match your directory).
   * Execute scripts `02` through `07` sequentially to run the exploratory, business, advanced, view, validation, and stored procedure queries.
2. **Explore the BI Dashboards:**
   * Open the `.pbix` file in **Power BI Desktop** or the `.twbx` file in **Tableau Desktop** to interact with the visuals.

---

## 👤 Author

**Santennagari Soma Sekhar**
* **GitHub:** [github.com/SantiSomaSekhar](https://github.com/SantiSomaSekhar)
* **LinkedIn:** [linkedin.com/in/soma-sekhar-santennagari-7569b72b9](https://www.linkedin.com/in/soma-sekhar-santennagari-7569b72b9)
