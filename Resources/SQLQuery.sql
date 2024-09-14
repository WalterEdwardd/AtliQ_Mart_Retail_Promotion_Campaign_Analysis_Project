--1/ list of products with a base price greater than 500, and promo type of 'BOGOF'
SELECT
    p.product_code,
    p.product_name,
    p.category,
    f.base_price,
    f.quantity_sold_before_promo
FROM fact_events AS f 
JOIN dim_products AS p 
ON f.product_code=p.product_code
WHERE base_price>500 AND promo_type='BOGOF';

-- EXPLANATION:
    -- SELECT: Specifies the columns to be returned in the result set
        -- product_code, product_name, and category: Identifies the product
        -- base_price: the original price of the product before any promotions
        -- quantity_sold_before_promo: the number of units sold of the product before promotions
    -- FROM fact_events AS f: Get data from fact_event table, aliased as f, contains sales data
    -- JOIN dim_products AS p: join dim_products table with fact_events table to obtain the product informations
    -- WHERE base_price>500 AND promo_type='BOGOF': filters the results based on two conditions:
        -- base_price greater than 500
        -- Promotion type is "BOGOF"


--2/ the number of stores in each city. The results will be sorted in descending order of store counts.
SELECT
    city,
    COUNT(DISTINCT store_id) AS total_store
FROM dim_stores
GROUP BY city
ORDER BY total_store DESC;

-- EXPLANATION:
    -- SELECT: Specifies the columns to be returned in the result set
        -- city: Retrieves the city name from the dim_stores table.
        -- COUNT(DISTINCT store_id): Counts the number of unique values in the store_id column for each group. The DISTINCT keyword ensures that each store is counted only once, even if it appears multiple times in the table. The AS total_store part gives an alias to the calculated count for better readability.
    -- FROM dim_stores: Get data from dim_stores table, contains stores data
    -- GROUP BY city: Groups the results by the city column. This means that the results will be calculated for each unique city.
    -- ORDER BY total_store DESC: Sorts the results in descending order based on the total_store column.


--3/ calculates total revenue generated before and after campaigns, considering different promotion types
WITH calculated_revenue AS
(
    SELECT
        c.campaign_name,
        ROUND(CAST(SUM(f.base_price * f.quantity_sold_before_promo) AS float) / 1000000.0, 2) AS total_revenue_before_promo_million,
        ROUND(CAST(SUM(
                        CASE
                            WHEN f.promo_type = '25% OFF' THEN f.base_price * 0.75 * f.quantity_sold_after_promo
                            WHEN f.promo_type = '33% OFF' THEN f.base_price * 0.67 * f.quantity_sold_after_promo
                            WHEN f.promo_type = '50% OFF' THEN f.base_price * 0.5 * f.quantity_sold_after_promo
                            WHEN f.promo_type = '500 Cashback' THEN (f.base_price - 500) * f.quantity_sold_after_promo
                            WHEN f.promo_type = 'BOGOF' THEN f.base_price * 0.5 * 2 * f.quantity_sold_after_promo
                        END) AS float) / 1000000.0, 2) AS total_revenue_after_promo_million
    FROM fact_events AS f 
    JOIN dim_campaigns AS c
    ON f.campaign_id = c.campaign_id
    GROUP BY campaign_name
)
SELECT
    *,
    ROUND(CAST((total_revenue_after_promo_million - total_revenue_before_promo_million) AS float) / total_revenue_before_promo_million * 100, 2) AS revenue_growth_rate
FROM calculated_revenue;

-- EXPLANATION:
    --1/ Common Table Expression (CTE) calculated_revenue:
    -- SELECT: Specifies the columns to be returned in the result set
        -- campaign_name: the name of the marketing campaign
        -- total_revenue_before_promo: the total revenue gererated before the promotion.
        -- total_revenue_after_promo: the total revenue gererated after the promotion.
        -- actual_revenue_after_promo: The actual revenue realized after applying the promotion, considering the specific promotion type
    -- FROM fact_events AS f: Get data from fact_event table, aliased as f, contains sales data
    -- JOIN dim_campaigns AS c: join dim_campaigns table with fact_events table to obtain the campaign informations
    -- GROUP BY campaign_name: Groups the results by the campaign_name column. This means that the results will be calculated for each unique campaign_name.
    --2/ Main Query:
    -- SELECT: selects the campaign name, total revenue before and after promotion
    -- Calculate the revenue growth rate between after and before the promotion.


--4/ Incremental Sold Quantity (ISU%) for each category during the Diwali campaign
WITH calculated_isu AS
(
    SELECT 
        p.category,
        SUM(f.quantity_sold_before_promo) AS total_quantity_sold_before_promo,
        SUM(
            CASE 
                WHEN f.promo_type = 'BOGOF' THEN f.quantity_sold_after_promo * 2
                ELSE f.quantity_sold_after_promo
            END) AS total_quantity_sold_after_promo,
        ROUND(CAST(SUM(
                        CASE 
                            WHEN f.promo_type = 'BOGOF' THEN f.quantity_sold_after_promo * 2
                            ELSE f.quantity_sold_after_promo
                        END
                        ) - SUM(f.quantity_sold_before_promo) AS FLOAT) / SUM(f.quantity_sold_before_promo) * 100, 2) AS [ISU%]
    FROM fact_events AS f 
    JOIN dim_products AS p ON f.product_code = p.product_code
    JOIN dim_campaigns AS c ON f.campaign_id = c.campaign_id
    WHERE c.campaign_name = 'Diwali'
    GROUP BY p.category
)
SELECT
    *,
    DENSE_RANK() OVER (ORDER BY [ISU%] DESC) AS rank
FROM calculated_isu;

-- EXPLANATION:
    --1/ Common Table Expression (CTE) calculated_isu:
    -- SELECT: Calculates the total quantity sold before and after promotion for each category.
    -- CASE expression: Adjusts the quantity sold based on the promotion type (BOGOF and others)
    -- Calculation:  Calculates the ISU percentage by subtracting the initial quantity sold from the adjusted quantity sold and dividing by the initial quantity, then converting to a percentage.
    --2/ Main Query:
    -- SELECT: Selects all columns from the calculated_isu CTE.
    -- DENSE_RANK() OVER: assigns a rank to each category based on the descending ISU percentage.


--5/ Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns
WITH calculated_revenue AS (
    SELECT 
        f.product_code,
        p.product_name,
        p.category,
        SUM(f.base_price * f.quantity_sold_before_promo) AS total_revenue_before_promo,
        SUM(
            CASE
                WHEN f.promo_type = '25% OFF' THEN f.base_price * 0.75 * f.quantity_sold_after_promo
                WHEN f.promo_type = '33% OFF' THEN f.base_price * 0.67 * f.quantity_sold_after_promo
                WHEN f.promo_type = '50% OFF' THEN f.base_price * 0.5 * f.quantity_sold_after_promo
                WHEN f.promo_type = '500 Cashback' THEN (f.base_price - 500) * f.quantity_sold_after_promo
                WHEN f.promo_type = 'BOGOF' THEN f.base_price * 0.5 * 2 * f.quantity_sold_after_promo
            END
        ) AS total_revenue_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY f.product_code, p.product_name, p.category
),
calculated_ir AS (
    SELECT 
        product_code,
        product_name,
        category,
        ROUND(CAST(total_revenue_before_promo AS float) / 1000000.0, 2) AS total_revenue_before_promo_million,
        ROUND(CAST(total_revenue_after_promo AS float) / 1000000.0, 2) AS total_revenue_after_promo_million,   
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / 1000000.0, 2) AS IR_million,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / total_revenue_before_promo * 100, 2) AS 'IR%'
    FROM calculated_revenue
)
SELECT TOP 5
    *,
    RANK() OVER(ORDER BY [IR%] DESC) AS rank_ir
FROM calculated_ir
ORDER BY rank_ir;

-- EXPLANATION:
    --1/ Common Table Expression (CTE) calculated_revenue:
    -- SELECT:
        -- total_revenue_before_promo: calculating the total revenue before promotion for each product and category
        -- total_revenue_after_promo: calculating the total revenue after promotion for each product and category
    -- CASE expression: determines the revenue calculation based on the promotion type
    --2/ Common Table Expression (CTE) calculated_ir:
    -- SELECT:
        -- IR_million: calculating the incremental revenue (IR_million) with the unit of million for each product and category
        -- IR%: calculating the incremental revenue percentage (IR%) for each product and category
    --3/ Main Query:
    -- SELECT TOP 5: Selects the top 5 products based on their rank_ir column
    -- RANK() OVER: assigns a rank to each product based on the descending IR% (Incremental Revenue Percentage)

--5/ Other Approach: Top 3 products, ranked by Incremental Revenue Percentage (IR%) and category, across all campaigns
WITH calculated_revenue AS
(
    SELECT 
        f.product_code,
        p.product_name,
        p.category,
        SUM(base_price * quantity_sold_before_promo) AS total_revenue_before_promo,
        SUM(
            CASE
                WHEN promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
                WHEN promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
                WHEN promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
                WHEN promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
                WHEN promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
            END
        ) AS total_revenue_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY f.product_code, p.product_name, p.category
),
calculated_ir AS
(
    SELECT 
        product_code,
        product_name,
        category,
        ROUND(CAST(total_revenue_before_promo AS float) / 1000000.0, 2) AS total_revenue_before_promo_million,
        ROUND(CAST(total_revenue_after_promo AS float) / 1000000.0, 2) AS total_revenue_after_promo_million,   
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / 1000000.0, 2) AS IR_million,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / total_revenue_before_promo * 100, 2) AS 'IR%'
    FROM calculated_revenue
),
arranged_rank AS
(
    SELECT
        *,
        RANK() OVER(PARTITION BY category ORDER BY [IR%] DESC) AS rank_ir
    FROM calculated_ir
)
SELECT
    *
FROM arranged_rank
WHERE rank_ir <=3
ORDER BY category, rank_ir;

-- EXPLANATION:
    --1/ Common Table Expression (CTE) calculated_revenue:
    -- SELECT:
        -- total_revenue_before_promo: calculating the total revenue before promotion for each product and category
        -- total_revenue_after_promo: calculating the total revenue after promotion for each product and category
    -- CASE expression: determines the revenue calculation based on the promotion type
    --2/ Common Table Expression (CTE) calculated_ir:
    -- SELECT:
        -- IR_million: calculating the incremental revenue (IR_million) with the unit of million for each product and category
        -- IR%: calculating the incremental revenue percentage (IR%) for each product and category
    --3/ Common Table Expression (CTE) arranged_rank:
    -- SELECT: Assigns a rank to each product within its category based on the descending IR percentage.
    --4/ Main Query:
    -- SELECT: Selects all columns from the arranged_rank CTE.
    -- WHERE: Filters for products with a rank less than or equal to 3 (top 3 in each category).
    -- ORDER BY: Orders the results by category and rank.












-- EXPLORATION DATA ANALYSIST:
--- I. STORE PERFORMANCE ANALYSIS
---- CARDS:
----- 1/ number of stores
SELECT 
    COUNT(store_id) AS number_of_store
FROM dim_stores;
--> the company currenly has 50 stores

----- 2/ number of cities
SELECT 
    COUNT(DISTINCT city) AS number_of_city
FROM dim_stores;
--> the company curently operates in 10 cities

----- 3/ total revenue
SELECT
    c.campaign_name,
    SUM(base_price * quantity_sold_before_promo) +
    SUM(
        CASE
            WHEN promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
            WHEN promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
            WHEN promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
            WHEN promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
            WHEN promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
        END) AS total_revenue
FROM fact_events AS f 
JOIN dim_campaigns AS c 
ON f.campaign_id=c.campaign_id
GROUP BY c.campaign_name;
--> total revenue to date is 436307831

----- 4/ total quantity sold
SELECT 
    c.campaign_name,
    SUM(quantity_sold_before_promo) +
    SUM(
        CASE
            WHEN promo_type = 'BOGOF' THEN 2 * quantity_sold_after_promo
            ELSE quantity_sold_after_promo
        END) AS total_quantity_sold
FROM fact_events AS f 
JOIN dim_campaigns AS c 
ON f.campaign_id=c.campaign_id
GROUP BY c.campaign_name;
--> and total quantity sold to date 859776

---- TABLES:
----- 1/ total store by city
SELECT
    city,
    COUNT(store_id) AS number_of_store
FROM dim_stores
GROUP BY city
ORDER BY number_of_store DESC;
--> Bengaluru í the city where the company is most active, with 10 stores. Followed by Chennai with 8 stores. Finally, there are Trivandrum and Vijayawada, both with 2 stores.

----- 2/ revenue before and after promotion by city
WITH cal_rev_by_city AS 
(
    SELECT
        s.city,
        c.campaign_name,
        ROUND(CAST(SUM(f.base_price * f.quantity_sold_before_promo) AS float) / 1000000.0, 2) AS total_revenue_before_promo_million,
        ROUND(CAST(SUM(
                        CASE
                            WHEN f.promo_type = '25% OFF' THEN f.base_price * 0.75 * f.quantity_sold_after_promo
                            WHEN f.promo_type = '33% OFF' THEN f.base_price * 0.67 * f.quantity_sold_after_promo
                            WHEN f.promo_type = '50% OFF' THEN f.base_price * 0.5 * f.quantity_sold_after_promo
                            WHEN f.promo_type = '500 Cashback' THEN (f.base_price - 500) * f.quantity_sold_after_promo
                            WHEN f.promo_type = 'BOGOF' THEN f.base_price * 0.5 * 2 * f.quantity_sold_after_promo
                        END) AS float) / 1000000.0, 2) AS total_revenue_after_promo_million
    FROM fact_events AS f 
    JOIN dim_stores AS s
    ON f.store_id=s.store_id
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY s.city, c.campaign_name
)
SELECT
    *,
    ROUND(CAST((total_revenue_after_promo_million - total_revenue_before_promo_million) AS float) / total_revenue_before_promo_million * 100, 2) AS revenue_growth_rate
FROM cal_rev_by_city
ORDER BY campaign_name, total_revenue_after_promo_million DESC;

----- 3/ top 10 stores by Incremental Revenue: IR = total revenue after promo - total revenue before promo
WITH cal_rev_by_store AS 
(
    SELECT 
        s.city,
        s.store_id,
        c.campaign_name,
        ROUND(CAST(SUM(f.base_price * f.quantity_sold_before_promo) AS float) / 1000000.0, 2) AS total_revenue_before_promo_million,
        ROUND(CAST(SUM(
                        CASE
                            WHEN f.promo_type = '25% OFF' THEN f.base_price * 0.75 * f.quantity_sold_after_promo
                            WHEN f.promo_type = '33% OFF' THEN f.base_price * 0.67 * f.quantity_sold_after_promo
                            WHEN f.promo_type = '50% OFF' THEN f.base_price * 0.5 * f.quantity_sold_after_promo
                            WHEN f.promo_type = '500 Cashback' THEN (f.base_price - 500) * f.quantity_sold_after_promo
                            WHEN f.promo_type = 'BOGOF' THEN f.base_price * 0.5 * 2 * f.quantity_sold_after_promo
                        END) AS float) / 1000000.0, 2) AS total_revenue_after_promo_million
    FROM fact_events AS f 
    JOIN dim_stores AS s
    ON f.store_id=s.store_id
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY s.store_id, s.city, campaign_name
),
cal_ir AS 
(
    SELECT
        *,
        ROUND(CAST((total_revenue_after_promo_million - total_revenue_before_promo_million) AS float), 2) AS IR_million,
        ROUND(CAST((total_revenue_after_promo_million - total_revenue_before_promo_million) AS float) / total_revenue_before_promo_million * 100, 2) AS 'IR%'
    FROM cal_rev_by_store
),
rank_ir AS 
(
    SELECT
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY IR_million DESC) AS IR_million_rank
    FROM cal_ir
)
SELECT 
    *
FROM rank_ir
WHERE IR_million_rank <=10
ORDER BY campaign_name, IR_million_rank;

----- 4/ bottom 10 stores by Incremental Revenue: IR = total revenue after promo - total revenue before promo
WITH cal_rev_by_store AS 
(
    SELECT 
        s.city,
        s.store_id,
        c.campaign_name,
        ROUND(CAST(SUM(f.base_price * f.quantity_sold_before_promo) AS float) / 1000000.0, 2) AS total_revenue_before_promo_million,
        ROUND(CAST(SUM(
                        CASE
                            WHEN f.promo_type = '25% OFF' THEN f.base_price * 0.75 * f.quantity_sold_after_promo
                            WHEN f.promo_type = '33% OFF' THEN f.base_price * 0.67 * f.quantity_sold_after_promo
                            WHEN f.promo_type = '50% OFF' THEN f.base_price * 0.5 * f.quantity_sold_after_promo
                            WHEN f.promo_type = '500 Cashback' THEN (f.base_price - 500) * f.quantity_sold_after_promo
                            WHEN f.promo_type = 'BOGOF' THEN f.base_price * 0.5 * 2 * f.quantity_sold_after_promo
                        END) AS float) / 1000000.0, 2) AS total_revenue_after_promo_million
    FROM fact_events AS f 
    JOIN dim_stores AS s
    ON f.store_id=s.store_id
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY s.store_id, s.city, campaign_name
),
cal_ir AS 
(
    SELECT
        *,
        ROUND(CAST((total_revenue_after_promo_million - total_revenue_before_promo_million) AS float), 2) AS IR_million,
        ROUND(CAST((total_revenue_after_promo_million - total_revenue_before_promo_million) AS float) / total_revenue_before_promo_million * 100, 2) AS 'IR%'
    FROM cal_rev_by_store
),
rank_ir AS 
(
    SELECT
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY IR_million) AS IR_million_rank
    FROM cal_ir
)
SELECT 
    *
FROM rank_ir
WHERE IR_million_rank <=10
ORDER BY campaign_name, IR_million_rank;

----- 5/ top 10 stores by Incremental Sold Units: ISU = total quantity sold after promo - total quantity sold before promo
WITH cal_qty_by_store AS 
(
    SELECT 
        s.city,
        s.store_id,
        c.campaign_name,
        SUM(f.quantity_sold_before_promo) AS total_quantity_sold_before_promo,
        SUM(
            CASE 
                WHEN f.promo_type = 'BOGOF' THEN f.quantity_sold_after_promo * 2
                ELSE f.quantity_sold_after_promo
            END) AS total_quantity_sold_after_promo
    FROM fact_events AS f 
    JOIN dim_stores AS s
    ON f.store_id=s.store_id
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY s.store_id, s.city, campaign_name
),
cal_isu AS 
(
    SELECT
        *,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float), 2) AS ISU,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float) / total_quantity_sold_before_promo * 100, 2) AS 'ISU%'
    FROM cal_qty_by_store
),
rank_isu AS 
(
    SELECT
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY ISU DESC) AS ISU_rank
    FROM cal_isu
)
SELECT 
    *
FROM rank_isu
WHERE ISU_rank <=10
ORDER BY campaign_name, ISU_rank;

----- 6/ bottom 10 stores by Incremental Sold Units: ISU = total quantity sold after promo - total quantity sold before promo
WITH cal_qty_by_store AS 
(
    SELECT 
        s.city,
        s.store_id,
        c.campaign_name,
        SUM(f.quantity_sold_before_promo) AS total_quantity_sold_before_promo,
        SUM(
            CASE 
                WHEN f.promo_type = 'BOGOF' THEN f.quantity_sold_after_promo * 2
                ELSE f.quantity_sold_after_promo
            END) AS total_quantity_sold_after_promo
    FROM fact_events AS f 
    JOIN dim_stores AS s
    ON f.store_id=s.store_id
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY s.store_id, s.city, campaign_name
),
cal_isu AS 
(
    SELECT
        *,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float), 2) AS ISU,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float) / total_quantity_sold_before_promo * 100, 2) AS 'ISU%'
    FROM cal_qty_by_store
),
rank_isu AS 
(
    SELECT
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY ISU) AS ISU_rank
    FROM cal_isu
)
SELECT 
    *
FROM rank_isu
WHERE ISU_rank <=10
ORDER BY campaign_name, ISU_rank;


--- II. PROMOTION TYPE ANALYSIS
---- CARDS:
----- 1/ total quantities sold before promotion and total revenue based on base price
SELECT
    c.campaign_name,
    SUM(quantity_sold_before_promo) AS total_quantity_sold_before_promo,
    SUM(quantity_sold_before_promo * base_price) AS base_price_revenue_before_promo
FROM fact_events AS f 
JOIN dim_campaigns AS c 
ON f.campaign_id=c.campaign_id
GROUP BY campaign_name;

----- 2/ total quantities sold after promotion and total revenue based on discount price
SELECT
    c.campaign_name,
    SUM(
        CASE 
            WHEN promo_type = 'BOGOF' THEN quantity_sold_after_promo * 2
            ELSE quantity_sold_after_promo
        END) AS total_quantity_sold_after_promo,
    ROUND(CAST(SUM(
                    CASE
                        WHEN promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
                        WHEN promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
                        WHEN promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
                        WHEN promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
                        WHEN promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
                    END) AS float), 2) AS total_revenue_after_promo
FROM fact_events AS f 
JOIN dim_campaigns AS c 
ON f.campaign_id=c.campaign_id
GROUP BY campaign_name;

----- 3/ incremental sold units and incremental revenue
SELECT
    c.campaign_name,
    ROUND(SUM(
        CASE 
            WHEN promo_type = 'BOGOF' THEN quantity_sold_after_promo * 2
            ELSE quantity_sold_after_promo
        END) - SUM(quantity_sold_before_promo), 2) AS ISU,
    ROUND(CAST(SUM(
                CASE
                    WHEN promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
                    WHEN promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
                    WHEN promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
                    WHEN promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
                    WHEN promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
                END) AS float) - SUM(quantity_sold_before_promo * base_price), 2) AS IR 
FROM fact_events AS f 
JOIN dim_campaigns AS c 
ON f.campaign_id=c.campaign_id
GROUP BY campaign_name;

----- 4/ incremental sold units percentage and incremental revenue percentage
SELECT 
    c.campaign_name,
    ROUND(CAST(SUM(
                    CASE 
                        WHEN promo_type = 'BOGOF' THEN quantity_sold_after_promo * 2
                        ELSE quantity_sold_after_promo
                    END) - SUM(quantity_sold_before_promo) AS float) / SUM(quantity_sold_before_promo) * 100, 2) AS [ISU%],
    ROUND(CAST(SUM(
                CASE
                    WHEN promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
                    WHEN promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
                    WHEN promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
                    WHEN promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
                    WHEN promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
                END) - SUM(quantity_sold_before_promo * base_price) AS float) / SUM(quantity_sold_before_promo * base_price) * 100, 2) AS [IR%]
FROM fact_events AS f 
JOIN dim_campaigns AS c 
ON f.campaign_id=c.campaign_id
GROUP BY campaign_name;

---- TABLES:
----- 1/ Promo types by incrementals sold units and incremental revenue
WITH raw_table AS
(
    SELECT 
        c.campaign_name,
        promo_type,
        SUM(quantity_sold_before_promo) AS total_quantity_sold_before_promo,
        SUM(
            CASE 
                WHEN promo_type = 'BOGOF' THEN quantity_sold_after_promo * 2
                ELSE quantity_sold_after_promo
            END) AS total_quantity_sold_after_promo,
        ROUND(CAST(SUM(base_price * quantity_sold_before_promo) AS float), 2) AS total_revenue_before_promo,
        ROUND(CAST(SUM(
                        CASE
                            WHEN promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
                            WHEN promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
                            WHEN promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
                            WHEN promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
                            WHEN promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
                            ELSE 0
                        END) AS float), 2) AS total_revenue_after_promo
    FROM fact_events AS f 
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, promo_type
)
SELECT
    campaign_name,
    promo_type,
    total_quantity_sold_before_promo,
    total_quantity_sold_after_promo,
    ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float), 2) AS ISU,
    ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float) / total_quantity_sold_before_promo * 100, 2) AS [ISU%],
    total_revenue_before_promo,
    total_revenue_after_promo,
    ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float), 2) AS IR,
    ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / total_revenue_before_promo * 100, 2) AS [IR%]
FROM raw_table
ORDER BY campaign_name, IR DESC;

----- 2/ Promo type and categories by quantities sold and revenue
------ 2.1/ Promo type and categories by incremental sold units and incremental sold unit percentage
WITH raw_table AS
(
    SELECT 
        c.campaign_name,
        f.promo_type,
        p.category,
        SUM(f.quantity_sold_before_promo) AS total_quantity_sold_before_promo,
        SUM(CASE
                WHEN f.promo_type='BOGOF' THEN f.quantity_sold_after_promo * 2
                ELSE quantity_sold_after_promo
            END ) AS total_quantity_sold_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, f.promo_type, p.category
)
SELECT 
    *,
    ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float), 2) AS ISU,
    ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float) / total_quantity_sold_before_promo * 100, 2) AS [ISU%]
FROM raw_table
ORDER BY campaign_name, promo_type;

------ 2.2/ Promo type and categories by incremental revenue and incremental revenue percentage
WITH raw_table AS
(
    SELECT 
        c.campaign_name,
        f.promo_type,
        p.category,
        ROUND(CAST(SUM(base_price * quantity_sold_before_promo) AS float), 2) AS total_revenue_before_promo,
        ROUND(CAST(SUM(
                        CASE 
                            WHEN promo_type='25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
                            WHEN promo_type='33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
                            WHEN promo_type='50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
                            WHEN promo_type='500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
                            WHEN promo_type='BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
                            ELSE 0
                        END) AS float), 2) AS total_revenue_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, f.promo_type, p.category
)
SELECT 
    *,
    ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float), 2) AS IR,
    ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / total_revenue_before_promo * 100, 2) AS [IR%]
FROM raw_table
ORDER BY campaign_name, promo_type;


----- 3/ Top Promo Type by Incremental Revenue and Incremental Revenue percentage
------ 3.1/ Top 2 promo type by IR
WITH raw_table AS
(
    SELECT
        c.campaign_name,
        f.promo_type,
        ROUND(CAST(SUM(base_price * quantity_sold_before_promo) AS float) / 1000000.0, 2) AS total_revenue_before_promo,
        ROUND(CAST(SUM(
                        CASE
                            WHEN f.promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
                            WHEN f.promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
                            WHEN f.promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
                            WHEN f.promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
                            WHEN f.promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
                            ELSE 0
                        END) AS float) / 1000000.0, 2) AS total_revenue_after_promo
    FROM fact_events AS f 
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, promo_type
),
cal_ir AS 
(
    SELECT
        *,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float), 2) AS IR,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / total_revenue_before_promo * 100, 2) AS [IR%]
    FROM raw_table
),
rank_ir AS
(
    SELECT 
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY IR DESC) AS IR_rank
    FROM cal_ir
)
SELECT
    *
FROM rank_ir
WHERE IR_rank <=2
ORDER BY campaign_name, IR_rank;

------ 3.2/ bottom 2 promo type by IR
WITH raw_table AS
(
    SELECT
        c.campaign_name,
        f.promo_type,
        ROUND(CAST(SUM(base_price * quantity_sold_before_promo) AS float) / 1000000.0, 2) AS total_revenue_before_promo,
        ROUND(CAST(SUM(
                        CASE
                            WHEN f.promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
                            WHEN f.promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
                            WHEN f.promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
                            WHEN f.promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
                            WHEN f.promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
                            ELSE 0
                        END) AS float) / 1000000.0, 2) AS total_revenue_after_promo

    FROM fact_events AS f 
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, promo_type
),
cal_ir AS 
(
    SELECT
        *,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float), 2) AS IR,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / total_revenue_before_promo * 100, 2) AS [IR%]
    FROM raw_table
),
rank_ir AS
(
    SELECT 
    *,
    RANK() OVER (PARTITION BY campaign_name ORDER BY IR) AS IR_rank
    FROM cal_ir
)
SELECT
    *
FROM rank_ir
WHERE IR_rank <=2
ORDER BY campaign_name, IR_rank;


----- 4/ Top Promo Type by Incremental Sold Unit and Incremental Sold Units Percentage
------ 4.1/ top 2 Promo type by ISU
WITH raw_table AS
(
    SELECT
        c.campaign_name,
        f.promo_type,
        SUM(quantity_sold_before_promo) AS total_quantity_sold_before_promo,
        SUM(
            CASE 
                WHEN promo_type = 'BOGOF' THEN quantity_sold_after_promo * 2
                ELSE quantity_sold_after_promo
            END) AS total_quantity_sold_after_promo
    FROM fact_events AS f 
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, promo_type
),
cal_isu AS 
(
    SELECT
        *,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float), 2) AS ISU,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float) / total_quantity_sold_before_promo * 100, 2) AS [ISU%]
    FROM raw_table
),
rank_isu AS 
(
    SELECT 
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY ISU DESC) AS ISU_rank
    FROM cal_isu
)
SELECT 
    *
FROM rank_isu
WHERE ISU_rank <=2
ORDER BY campaign_name, ISU_rank;

------ 4.2/ bottom 2 Promo type by ISU
WITH raw_table AS
(
    SELECT
        c.campaign_name,
        f.promo_type,
        SUM(quantity_sold_before_promo) AS total_quantity_sold_before_promo,
        SUM(
            CASE 
                WHEN promo_type = 'BOGOF' THEN quantity_sold_after_promo * 2
                ELSE quantity_sold_after_promo
            END) AS total_quantity_sold_after_promo
    FROM fact_events AS f 
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, promo_type
),
cal_isu AS 
(
    SELECT
        *,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float), 2) AS ISU,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float) / total_quantity_sold_before_promo * 100, 2) AS [ISU%]
    FROM raw_table
),
rank_isu AS 
(
    SELECT 
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY ISU) AS ISU_rank
    FROM cal_isu
)
SELECT 
    *
FROM rank_isu
WHERE ISU_rank <=2
ORDER BY campaign_name, ISU_rank;


----- 5/ promotion type best balance between incremental sold unit and maintaining healthy margins
-- EXPLANATION:
-- more detail


--- III. CATEGORY AND PRODUCT ANALYSIS
---- CARDS:
----- 1/ number of categories
SELECT
    COUNT(DISTINCT category) AS number_of_category
FROM dim_products

----- 2/ number of products
SELECT
    COUNT(product_code) AS number_of_product
FROM dim_products

----- 3/ total revenue
SELECT 
    SUM(base_price * quantity_sold_before_promo) +
    SUM(
        CASE
            WHEN promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
            WHEN promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
            WHEN promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
            WHEN promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
            WHEN promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
        END) AS total_revenue
FROM fact_events

----- 4/ total quantity sold
SELECT 
    SUM(quantity_sold_before_promo) +
    SUM(
        CASE
            WHEN promo_type = 'BOGOF' THEN 2 * quantity_sold_after_promo
            ELSE quantity_sold_after_promo
        END) AS total_quantity_sold
FROM fact_events;


---- TABLES:
----- 1/ top product categories lift in sales after promotion
------ 1.1/ top categories by incremental sold units
WITH raw_table AS
(   
    SELECT
        c.campaign_name,
        p.category,
        SUM(f.quantity_sold_before_promo) AS total_quantity_sold_before_promo,
        SUM(
            CASE
                WHEN f.promo_type='BOGOF' THEN f.quantity_sold_after_promo * 2
                ELSE quantity_sold_after_promo
            END 
            ) AS total_quantity_sold_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, p.category
),
cal_isu AS 
(
    SELECT
        *,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float), 2) AS ISU,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float) / total_quantity_sold_before_promo * 100, 2) AS [ISU%]
    FROM raw_table
),
rank_isu AS 
(
    SELECT
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY ISU DESC) AS ISU_rank
   FROM cal_isu
)
SELECT 
    *
FROM rank_isu
WHERE ISU_rank<=3
ORDER BY campaign_name, ISU_rank;

------ 1.2/ top categories by incremental revenue
WITH raw_table AS 
(
    SELECT
        c.campaign_name,
        p.category,
        SUM(base_price * quantity_sold_before_promo) AS total_revenue_before_promo,
        SUM(
            CASE
                WHEN f.promo_type= '25% OFF' THEN f.base_price * 0.75 * f.quantity_sold_after_promo
                WHEN f.promo_type= '33% OFF' THEN f.base_price * 0.67 * f.quantity_sold_after_promo
                WHEN f.promo_type= '50% OFF' THEN f.base_price * 0.5 * f.quantity_sold_after_promo
                WHEN f.promo_type= '500 Cashback' THEN (f.base_price - 500) * f.quantity_sold_after_promo
                WHEN f.promo_type= 'BOGOF' THEN f.base_price * 0.5 * 2 * f.quantity_sold_after_promo
            END) AS total_revenue_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, p.category
),
cal_ir AS 
(
    SELECT
        *,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float), 2) AS IR,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / total_revenue_before_promo * 100, 2) AS [IR%]
    FROM raw_table
),
rank_ir AS 
(
    SELECT
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY IR DESC) AS IR_rank
   FROM cal_ir
)
SELECT 
    *
FROM rank_ir
WHERE IR_rank<=3
ORDER BY campaign_name, IR_rank;

----- 2/ category and product by revenue and quantity sold
WITH raw_table AS
(
    SELECT 
        c.campaign_name,
        p.category,
        p.product_name,
        f.promo_type,
        SUM(quantity_sold_before_promo) AS total_quantity_sold_before_promo,
        SUM(
            CASE 
                WHEN promo_type = 'BOGOF' THEN quantity_sold_after_promo * 2
                ELSE quantity_sold_after_promo
            END) AS total_quantity_sold_after_promo,
        ROUND(CAST(SUM(base_price * quantity_sold_before_promo) AS float), 2) AS total_revenue_before_promo,
        ROUND(CAST(SUM(
                        CASE
                            WHEN promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
                            WHEN promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
                            WHEN promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
                            WHEN promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
                            WHEN promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
                            ELSE 0
                        END) AS float), 2) AS total_revenue_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, p.category, p.product_name, f.promo_type
)
SELECT
    campaign_name,
    category,
    product_name,
    promo_type,
    total_quantity_sold_before_promo,
    total_quantity_sold_after_promo,
    ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float), 2) AS ISU,
    ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float) / total_quantity_sold_before_promo * 100, 2) AS [ISU%],
    total_revenue_before_promo,
    total_revenue_after_promo,
    ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float), 2) AS IR,
    ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / total_revenue_before_promo * 100, 2) AS [IR%]
FROM raw_table
ORDER BY campaign_name, IR DESC;

----- 3/ top products by incremental revenue and incremental revenue percentage
------ 3.1/ top 5 product by IR
WITH raw_table AS
(
    SELECT 
        c.campaign_name,
        p.category,
        p.product_name,
        promo_type,
        ROUND(CAST(SUM(base_price * quantity_sold_before_promo) AS float), 2) AS total_revenue_before_promo,
        ROUND(CAST(SUM(
                        CASE
                            WHEN promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
                            WHEN promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
                            WHEN promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
                            WHEN promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
                            WHEN promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
                            ELSE 0
                        END) AS float), 2) AS total_revenue_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, p.category, p.product_name, promo_type
),
cal_ir AS
(
    SELECT
        *,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float), 2) AS IR,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / total_revenue_before_promo * 100, 2) AS [IR%]
    FROM raw_table
),
rank_ir AS 
(
    SELECT
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY IR DESC) AS IR_rank
    FROM cal_ir
)
SELECT 
    *
FROM rank_ir
WHERE IR_rank<=5
ORDER BY campaign_name, IR_rank;

------ 3.2/ top 5 product by IR%
WITH raw_table AS
(
    SELECT 
        c.campaign_name,
        p.category,
        p.product_name,
        promo_type,
        ROUND(CAST(SUM(base_price * quantity_sold_before_promo) AS float), 2) AS total_revenue_before_promo,
        ROUND(CAST(SUM(
                        CASE
                            WHEN promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
                            WHEN promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
                            WHEN promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
                            WHEN promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
                            WHEN promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
                            ELSE 0
                        END) AS float), 2) AS total_revenue_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, p.category, p.product_name, promo_type
),
cal_ir AS
(
    SELECT
        *,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float), 2) AS IR,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / total_revenue_before_promo * 100, 2) AS [IR%]
    FROM raw_table
),
rank_ir AS 
(
    SELECT
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY [IR%] DESC) AS [IR%_rank]
    FROM cal_ir
)
SELECT 
    *
FROM rank_ir
WHERE [IR%_rank]<=5
ORDER BY campaign_name, [IR%_rank];

------ 3.3/ bottom 5 product by IR
WITH raw_table AS
(
    SELECT 
        c.campaign_name,
        p.category,
        p.product_name,
        promo_type,
        ROUND(CAST(SUM(base_price * quantity_sold_before_promo) AS float), 2) AS total_revenue_before_promo,
        ROUND(CAST(SUM(
                        CASE
                            WHEN promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
                            WHEN promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
                            WHEN promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
                            WHEN promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
                            WHEN promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
                            ELSE 0
                        END) AS float), 2) AS total_revenue_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, p.category, p.product_name, promo_type
),
cal_ir AS
(
    SELECT
        *,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float), 2) AS IR,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / total_revenue_before_promo * 100, 2) AS [IR%]
    FROM raw_table
),
rank_ir AS 
(
    SELECT
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY IR) AS IR_rank
    FROM cal_ir
)
SELECT 
    *
FROM rank_ir
WHERE IR_rank<=5
ORDER BY campaign_name, IR_rank;

------ 3.4/ bottom 5 product by IR%
WITH raw_table AS
(
    SELECT 
        c.campaign_name,
        p.category,
        p.product_name,
        promo_type,
        ROUND(CAST(SUM(base_price * quantity_sold_before_promo) AS float), 2) AS total_revenue_before_promo,
        ROUND(CAST(SUM(
                        CASE
                            WHEN promo_type = '25% OFF' THEN base_price * 0.75 * quantity_sold_after_promo
                            WHEN promo_type = '33% OFF' THEN base_price * 0.67 * quantity_sold_after_promo
                            WHEN promo_type = '50% OFF' THEN base_price * 0.5 * quantity_sold_after_promo
                            WHEN promo_type = '500 Cashback' THEN (base_price - 500) * quantity_sold_after_promo
                            WHEN promo_type = 'BOGOF' THEN base_price * 0.5 * 2 * quantity_sold_after_promo
                            ELSE 0
                        END) AS float), 2) AS total_revenue_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, p.category, p.product_name, promo_type
),
cal_ir AS
(
    SELECT
        *,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float), 2) AS IR,
        ROUND(CAST((total_revenue_after_promo - total_revenue_before_promo) AS float) / total_revenue_before_promo * 100, 2) AS [IR%]
    FROM raw_table
),
rank_ir AS 
(
    SELECT
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY [IR%]) AS [IR%_rank]
    FROM cal_ir
)
SELECT 
    *
FROM rank_ir
WHERE [IR%_rank]<=5
ORDER BY campaign_name, [IR%_rank];

----- 4/ top products by incremental sold units and incremental sold units percentage
------ 4.1/ top 5 product by ISU
WITH raw_table AS
(
    SELECT
        C.campaign_name,
        p.category,
        p.product_name,
        promo_type,
        SUM(quantity_sold_before_promo) AS total_quantity_sold_before_promo,
        SUM(
            CASE 
                WHEN promo_type = 'BOGOF' THEN quantity_sold_after_promo * 2
                ELSE quantity_sold_after_promo
            END) AS total_quantity_sold_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, p.category, p.product_name, promo_type
),
cal_isu AS 
(
    SELECT 
        *,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float), 2) AS ISU,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float) / total_quantity_sold_before_promo * 100, 2) AS [ISU%]
    FROM raw_table
),
rank_isu AS 
(
    SELECT 
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY ISU DESC) AS ISU_rank
    FROM cal_isu
)
SELECT 
    *
FROM rank_isu
WHERE ISU_rank<=5
ORDER BY campaign_name, ISU_rank;

------ 4.2/ top 5 product by ISU%
WITH raw_table AS
(
    SELECT
        C.campaign_name,
        p.category,
        p.product_name,
        promo_type,
        SUM(quantity_sold_before_promo) AS total_quantity_sold_before_promo,
        SUM(
            CASE 
                WHEN promo_type = 'BOGOF' THEN quantity_sold_after_promo * 2
                ELSE quantity_sold_after_promo
            END) AS total_quantity_sold_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, p.category, p.product_name, promo_type
),
cal_isu AS 
(
    SELECT 
        *,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float), 2) AS ISU,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float) / total_quantity_sold_before_promo * 100, 2) AS [ISU%]
    FROM raw_table
),
rank_isu AS 
(
    SELECT 
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY [ISU%] DESC) AS [ISU%_rank]
    FROM cal_isu
)
SELECT 
    *
FROM rank_isu
WHERE [ISU%_rank]<=5
ORDER BY campaign_name, [ISU%_rank];

------ 4.3/ bottom 5 product by ISU
WITH raw_table AS
(
    SELECT
        C.campaign_name,
        p.category,
        p.product_name,
        promo_type,
        SUM(quantity_sold_before_promo) AS total_quantity_sold_before_promo,
        SUM(
            CASE 
                WHEN promo_type = 'BOGOF' THEN quantity_sold_after_promo * 2
                ELSE quantity_sold_after_promo
            END) AS total_quantity_sold_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, p.category, p.product_name, promo_type
),
cal_isu AS 
(
    SELECT 
        *,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float), 2) AS ISU,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float) / total_quantity_sold_before_promo * 100, 2) AS [ISU%]
    FROM raw_table
),
rank_isu AS 
(
    SELECT 
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY ISU) AS ISU_rank
    FROM cal_isu
)
SELECT 
    *
FROM rank_isu
WHERE ISU_rank<=5
ORDER BY campaign_name, ISU_rank;

------ 4.4/ bottom 5 product by ISU%
WITH raw_table AS
(
    SELECT
        C.campaign_name,
        p.category,
        p.product_name,
        promo_type,
        SUM(quantity_sold_before_promo) AS total_quantity_sold_before_promo,
        SUM(
            CASE 
                WHEN promo_type = 'BOGOF' THEN quantity_sold_after_promo * 2
                ELSE quantity_sold_after_promo
            END) AS total_quantity_sold_after_promo
    FROM fact_events AS f 
    JOIN dim_products AS p 
    ON f.product_code=p.product_code
    JOIN dim_campaigns AS c 
    ON f.campaign_id=c.campaign_id
    GROUP BY c.campaign_name, p.category, p.product_name, promo_type
),
cal_isu AS 
(
    SELECT 
        *,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float), 2) AS ISU,
        ROUND(CAST((total_quantity_sold_after_promo - total_quantity_sold_before_promo) AS float) / total_quantity_sold_before_promo * 100, 2) AS [ISU%]
    FROM raw_table
),
rank_isu AS 
(
    SELECT 
        *,
        RANK() OVER (PARTITION BY campaign_name ORDER BY [ISU%]) AS [ISU%_rank]
    FROM cal_isu
)
SELECT 
    *
FROM rank_isu
WHERE [ISU%_rank]<=5
ORDER BY campaign_name, [ISU%_rank];
