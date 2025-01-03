-- 1.Import the dataset and do usual exploratory analysis steps like checking the structure & characteristics of the dataset:

-- Data type of all columns in the "customers" table.

SELECT *
FROM `Target.customers`;

-- Get the time range between which the orders were placed.

SELECT
	MIN(order_purchase_timestamp) AS end_order_date, 
	MAX(order_purchase_timestamp) AS start_order_date
FROM `Target.orders` ;

-- Count the Cities & States of customers who ordered during the given period.

SELECT
	DISTINCT customer_city, 
	customer_state
FROM `Target.customers` AS tc
JOIN `Target.orders` AS o
ON tc. customer_id = o. customer_id
WHERE o.order_purchase_timestamp >= '2016-09-04' AND o.order_purchase_timestamp<= '2018-10-17';


SELECT
	COUNT (customer_city) AS total_no_of_city,
	COUNT(DISTINCT customer_state) total_no_of_state
FROM (
	SELECT
		DISTINCT (customer_city),
		customer_state
	FROM `Target.customers` AS tc
	JOIN `Target.orders` AS o
	ON tc. customer_id = o. customer_id
)

-- 2. In-depth Exploration:

-- Is there a growing trend in the no. of orders placed over the past years?

SELECT
	year,
	COUNT (order_id) AS no_of_orders
FROM (
	SELECT
	EXTRACT (YEAR FROM order_purchase_timestamp) AS year, 
	order_id
	FROM `Target.orders`
)
GROUP BY year
ORDER BY no_of_orders;

-- Can we see some kind of monthly seasonality in terms of the no. of orders being placed?

SELECT
	EXTRACT (MONTH FROM order_purchase_timestamp) AS month,
	COUNT (*) AS ordercount
FROM `Target.orders`
GROUP BY month
ORDER BY month;

-- During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
   0-6 hrs : Dawn
   7-12 hrs : Mornings
   13-18 hrs : Afternoon
   19-23 hrs : Night

SELECT
	CASE
		WHEN EXTRACT(HOUR FROM o.order_purchase_timestamp) BETWEEN 0 AND 6 THEN 'Dawn'
		WHEN EXTRACT(HOUR FROM o.order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Morning'
		WHEN EXTRACT(HOUR FROM o.order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
		WHEN EXTRACT(HOUR FROM o.order_purchase_timestamp) BETWEEN 19 AND 23 THEN 'Night'
	END AS hour,
	COUNT(o.order_id) AS ordercount
FROM `Target.orders` AS o
JOIN `Target customers` AS c
ON o.customer_id = c.customer_id
GROUP BY hour
ORDER BY ordercount DESC;

-- 3.  Evolution of E-commerce orders in the Brazil region:

-- Get the month on month no. of orders placed in each state.

SELECT
	c. customer_state,
	EXTRACT (MONTH FROM order_purchase_timestamp) AS month,
	COUNT (o.order_id) AS ordercount
FROM `Target.orders` AS o
JOIN `Target.customers` AS c
ON o.customer_id = c. customer _id
GROUP BY month, c.customer_state
ORDER BY month, c.customer_state;

-- How are the customers distributed across all the states?

SELECT
	customer_state,
	COUNT(*) AS customer_count
FROM `Target.customer`
GROUP BY customer_state
ORDER BY customer_count DESC;

-- 4. Impact on Economy: Analyze the money movement by e-commerce by looking at order prices, freight and others.

-- Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).

WITH orders_2017 AS (
	SELECT
		SUM (p.payment_value) As total_cost_2017
	FROM `Target.payments` AS p
	JOIN `Target.orders` AS o
	ON p.order_id = o.order_id
	WHERE EXTRACT(YEAR FROM order_purchase_timestamp) = 2017
	AND EXTRACT (MONTH FROM order_purchase_timestamp) BETWEEN 1 AND 8
),
orders_2018 AS (
	SELECT
	SUM(p.payment_value) AS total_cost_2018
	FROM `Target.payments` AS P
	JOIN `Target.orders` AS o
	ON p.order_id = o.order_id
	WHERE EXTRACT(YEAR FROM order-_purchase_timestamp) = 2018
	AND EXTRACT (MONTH FROM order_purchase_timestamp) BETWEEN 1 AND 8
)
SELECT
	ROUND((orders_2018.total_cost_2018 - orders_2017.total_cost_2017) / orders_2017.total_cost_2017 * 100, 2) AS cost_increase_percentage
FROM orders_2017, orders_2018;

-- Calculate the Total & Average value of order price for each state.

SELECT
	c.customer_state,
	ROUND(SUM(p.payment_value), 2) AS total_order_price,
	ROUND(AVG(p.payment_value), 2) AS average_order-price
FROM `Target.customers` AS c
LEFT JOIN (
	SELECT
		o.customer_id,
    	p.payment_value
	FROM `Target.orders` AS o
	JOIN `Target.payments` AS p
	ON o.order_id = p.order_id
) AS p
ON c.customer_id = p.customer_id
GROUP BY c.customer_state
ORDER BY total_order_price DESC, average_order_price DESC;

-- Calculate the Total & Average value of order freight for each state.

SELECT
	c.customer_state,
	ROUND(SUM(ot.freight_value), 2) AS total_freight_value, 
	ROUND(AVG(ot.freight_value), 2) AS average_freight_value
FROM `Target.customers` AS c
LEFT JOIN (
	SELECT
		o.customer_id, 
		ot.freight_value
	FROM `Target.orders` AS o
	JOIN `Target.order_items` AS ot
	ON o.order_id = ot.order_id
) AS ot
ON c.customer_id = ot.customer_id
GROUP BY c.customer_state
ORDER BY total_freight_value DESC, average_freight_value DESC;

-- 5.  Analysis based on sales, freight and delivery time.

-- Find the no. of days taken to deliver each order from the order’s purchase date as delivery time. Also, calculate the difference (in days) between the estimated & actual delivery date of an order. Do this in a single query.

SELECT
	order_id, 
	order_purchase_timestamp, 
	order_estimated_delivery_date, 
	order_delivered_customer_date,
	TIMESTAMP_DIFF (order_estimated_delivery_date, order_delivered_customer_date, DAY) AS diff_estimated_delivery,
	TIMESTAMP_DIFF (order_delivered_customer_date, order_purchase_timestamp, DAY) AS delivery_time
FROM `Target.orders`
GROUP BY order_id, order-purchase_timestamp, order_estimated_delivery_date, order_delivered_customer_date
ORDER BY order_purchase_timestamp;

-- Find out the top 5 states with the highest & lowest average freight value.

-- Highest

SELECT
	c. customer_state,
	ROUND (AVG(ot.freight_value), 2) AS Avg_freight_value
FROM `Target.customers` AS c
LEFT JOIN (
	SELECT
		o.customer_id, 
		ot.freight_value
	FROM `Target.orders` AS o
	JOIN `Target.order_items`AS ot
	ON o.order_id = ot.order_id
) AS ot
ON c.customer_id = ot.customer_id
GROUP BY c.customer_state
ORDER BY Avg_freight_value DESC
LIMIT 5;

-- Lowest

SELECT
	c.customer_state,
	ROUND(AVG(ot.freight_value), 2) AS Avg_freight_value
	FROM `Target.customers` AS c
LEFT JOIN (
	SELECT
		o.customer_id, 
		ot.freight_value
	FROM `Target.orders` AS o
	JOIN `Target.order_items`AS ot
	ON o.order_id = ot.order_id
) AS ot
ON c.customer_id = ot.customer_id
GROUP BY c.customer_state
ORDER BY Avg_freight_value
LIMIT 5;

-- Find out the top 5 states with the highest & lowest average delivery time.

-- Highest

WITH state_delivery_avg AS (
	SELECT
		c.customer_state,
		ROUND(AVG(TIMESTAMP_DIFF(order _delivered_customer_date, order_purchase_timestamp, DAY)), 2) AS avg_delivery_time
	FROM `Target.orders` AS o
	JOIN `Target.customers` AS c 
	ON o.customer_id = c.customer_id
	GROUP BY c.customer_state
)
SELECT
	customer_state, 
	avg_delivery_time
FROM state_delivery_avg
ORDER BY avg_delivery_time DESC
LIMIT 5;

-- Lowest

WITH state_delivery_avg AS (
	SELECT
		c.customer_state,
		ROUND(AVG(TIMESTAMP_DIFF(order _delivered_customer_date, order_purchase_timestamp, DAY)), 2) AS avg_delivery_time
	FROM `Target.orders` AS o
	JOIN `Target.customers` AS c 
	ON o.customer_id = c.customer_id
	GROUP BY c.customer_state
)
SELECT
	customer_state, 
	avg_delivery_time
FROM state_delivery_avg
ORDER BY avg_delivery_time
LIMIT 5;

-- Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.

WITH state_delivery_avg AS (
	SELECT
		c.customer_state,
		ROUND(AVG (TIMESTAMP_DIFF (order _delivered_customer_date, order_estimated_delivery_date, DAY)), 2) AS avg_fast_delivery
	FROM `Target.orders` AS o
	JOIN `Target.customers` AS c 
	ON o.customer_id = c.customer_id
	GROUP BY c.customer_state
)
SELECT
	customer_state, 
	state_delivery_avg.avg_fast_delivery
FROM state_delivery_avg
ORDER BY state_delivery_avg.avg_fast_delivery
LIMIT 5;

-- 6.  Analysis based on the payments:

-- Find the month on month no. of orders placed using different payment types.

SELECT
	FORMAT_TIMESTAMP ('%Y-%m', order_purchase_timestamp) AS month,
	payment_type,
	COUNT (p.order_id) AS order_count
FROM `Target.orders` AS o
JOIN `Target.payments` AS p
ON o.order_id = p.order_id
GROUP BY month, payment_type 
ORDER BY month, payment_type;


SELECT
	DISTINCT payment_type,
	COUNT(order_id) OVER(PARTITION BY payment_type) AS ordercount
FROM `Target.payments`

-- Find the no. of orders placed on the basis of the payment installments that have been paid.

SELECT
	payment_installments_paid_in,
	COUNT(order_id) AS order_count
FROM (
	SELECT
		order_id,
		COUNT(payment_installments) AS payment_installments_paid_in
	FROM `Target.payments`
	WHERE payment_installments > 0
	GROUP BY order_id
)
GROUP BY payment_installments_paid_in
ORDER BY payment_installments_paid_in;


