select * from sales;
select * from products;
select * from customers;
select * from city;

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT city_name,
ROUND((population * 0.25)/1000000, 2) as coffee_consumers_in_millions,city_rank
FROM city
ORDER BY 2 DESC;


-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT  
 SUM(total) as total_revenue
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date)  = 2023
	AND
	EXTRACT(quarter FROM sale_date) = 4;

-- Q.3
-- Which cities generated the highest total sales revenue in the 4th quarter of 2023?

SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)  = 2023
	AND
	EXTRACT(quarter FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;


-- Q.4
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;


-- Q.5
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

SELECT ci.city_name,
       SUM(s.total) AS total_revenue,
       COUNT(DISTINCT s.customer_id) AS total_cx,
       ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_pr_cx
FROM sales AS s
JOIN customers AS c ON s.customer_id = c.customer_id
JOIN city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;


-- Q.6
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT * FROM products;



SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1;

-- Q.7
-- Find the most loyal customers (most frequent buyers).

SELECT cu.customer_name, COUNT(*) AS total_purchases
FROM sales s
JOIN customers cu ON s.customer_id = cu.customer_id
GROUP BY cu.customer_name
ORDER BY total_purchases DESC
LIMIT 10;


-- Q.8
-- What is the average rent and population of cities where sales occurred?

SELECT c.city_name, AVG(c.population) AS avg_population, AVG(c.estimated_rent) AS avg_rent
FROM sales s
JOIN customers cu ON s.customer_id = cu.customer_id
JOIN city c ON cu.city_id = c.city_id
GROUP BY c.city_name;

-- Q.9
-- What is the monthly sales trend?

SELECT DATE_FORMAT(sale_date, '%Y-%m') AS month, SUM(total) AS monthly_sales
FROM sales
GROUP BY month
ORDER BY month;


-- Q.10
-- Which customers gave the most 5-star ratings?

SELECT cu.customer_name, COUNT(*) AS five_star_ratings
FROM sales s
JOIN customers cu ON s.customer_id = cu.customer_id
WHERE s.rating = 5
GROUP BY cu.customer_name
ORDER BY five_star_ratings DESC;


-- Q.11
-- Which products have the highest average price?

SELECT product_name, price
FROM products
ORDER BY price DESC
LIMIT 5;


-- Q.12
--  Find the top 3 products with the highest average rating in each city.

SELECT city_name, product_name, avg_rating
FROM (
    SELECT 
        ci.city_name,
        p.product_name,
        ROUND(AVG(s.rating), 2) AS avg_rating,
        RANK() OVER (PARTITION BY ci.city_name ORDER BY ROUND(AVG(s.rating), 2) DESC) AS `rank`
    FROM sales s
    JOIN customers cu ON s.customer_id = cu.customer_id
    JOIN city ci ON cu.city_id = ci.city_id
    JOIN products p ON s.product_id = p.product_id
    GROUP BY ci.city_name, p.product_name
) ranked
WHERE `rank` <= 3;


-- Q.13
--  Find customers who have purchased products worth more than ₹2000 in total.

SELECT cu.customer_name, SUM(s.total) AS total_spent
FROM sales s
JOIN customers cu ON s.customer_id = cu.customer_id
GROUP BY cu.customer_name
HAVING SUM(s.total) > 2000
ORDER BY total_spent DESC;


-- Q.14
-- Which city has the highest average order value?

SELECT c.city_name, ROUND(AVG(s.total), 2) AS avg_order_value
FROM sales s
JOIN customers cu ON s.customer_id = cu.customer_id
JOIN city c ON cu.city_id = c.city_id
GROUP BY c.city_name
ORDER BY avg_order_value DESC
LIMIT 1;


-- Q.15
-- Show monthly revenue growth rate (MoM %).

WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(sale_date, '%Y-%m') AS month,
        SUM(total) AS revenue
    FROM sales
    GROUP BY month
),
growth_rate AS (
    SELECT 
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_revenue
    FROM monthly_sales
)
SELECT 
    month,
    revenue,
    ROUND((revenue - previous_revenue) / previous_revenue * 100, 2) AS growth_percentage
FROM growth_rate
WHERE previous_revenue IS NOT NULL;


-- Q.16
-- List top 5 customers in each city by total purchase amount.

SELECT city_name, customer_name, total_spent
FROM (
    SELECT 
        c.city_name,
        cu.customer_name,
        SUM(s.total) AS total_spent,
        RANK() OVER (PARTITION BY c.city_name ORDER BY SUM(s.total) DESC) AS city_rank
    FROM sales s
    JOIN customers cu ON s.customer_id = cu.customer_id
    JOIN city c ON cu.city_id = c.city_id
    GROUP BY c.city_name, cu.customer_name
) ranked_customers
WHERE city_rank <= 5;

-- Q.17
-- Which product has the highest sales-to-price ratio?

SELECT p.product_name, 
       SUM(s.total) / p.price AS sales_to_price_ratio
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name, p.price
ORDER BY sales_to_price_ratio DESC
LIMIT 1;

-- Q.18
-- Identify the best performing city considering rating and revenue.

SELECT 
    c.city_name,
    ROUND(AVG(s.rating), 2) AS avg_rating,
    SUM(s.total) AS total_revenue,
    ROUND(AVG(s.rating) * SUM(s.total), 2) AS performance_score
FROM sales s
JOIN customers cu ON s.customer_id = cu.customer_id
JOIN city c ON cu.city_id = c.city_id
GROUP BY c.city_name
ORDER BY performance_score DESC;


-- Q.19
-- Get the average rating per product, and the difference from the overall average rating.

SELECT 
    p.product_name,
    ROUND(AVG(s.rating), 2) AS avg_product_rating,
    ROUND(AVG(s.rating) - (SELECT AVG(rating) FROM sales), 2) AS rating_diff
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_id, p.product_name;

-- Q.20
-- Get the average sale amount for each customer and how it compares to the overall average.

SELECT 
    cu.customer_name,
    ROUND(AVG(s.total), 2) AS avg_customer_total,
    ROUND(AVG(s.total) - (SELECT AVG(total) FROM sales), 2) AS diff_from_global_avg
FROM sales s
JOIN customers cu ON s.customer_id = cu.customer_id
GROUP BY cu.customer_id, cu.customer_name;

