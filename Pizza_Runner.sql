CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
  
--  Data Cleaning

-- data cleaning on customer_orders;

UPDATE customer_orders 
SET extras = NULL
WHERE extras = '' OR extras = 'null';

UPDATE customer_orders 
SET exclusions = NULL
WHERE exclusions = '' OR exclusions = 'null';

-- Data cleaning on runner orders
SELECT * FROM runner_orders;

UPDATE runner_orders
SET duration = CAST(SPLIT_PART(duration, 'min', 1) AS INT)
WHERE duration LIKE '__min%' OR duration LIKE '___min%';

UPDATE runner_orders
SET duration = NULL
WHERE duration = 'null';

UPDATE runner_orders
SET distance = REPLACE(distance, 'km', '')

UPDATE runner_orders
SET distance = NULL
WHERE distance = 'null';

UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = 'null';

UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation = 'null' OR cancellation = '';

SELECT * FROM pizza_recipes;


-- A. Pizza Metrics
-- A1. How many pizzas were ordered?

SELECT 
	COUNT(order_id) 
FROM 
	customer_orders;


-- A2. How many unique customer orders were made?

SELECT 
	COUNT(DISTINCT(customer_id)) 
FROM 
	customer_orders;


-- A3. How many successful orders were delivered by each runner?

SELECT 
	runner_id, COUNT(*) 
FROM 
	runner_orders 
WHERE 
	cancellation IS NULL
GROUP BY 
	runner_id;


-- A4. How many of each type of pizza was delivered?

SELECT 
	pizza_id, COUNT(*) 
FROM 
	customer_orders 
GROUP BY 
	pizza_id;

-- A5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT customer_id,
	SUM(
		CASE WHEN pizza_name = 'Vegetarian' THEN 1 ELSE 0
	END) AS Vegetarian,
	
	SUM(
		CASE WHEN pizza_name = 'Meatlovers' THEN 1 ELSE 0
	END) AS Meatlovers
FROM pizza_names JOIN customer_orders USING(pizza_id) GROUP BY customer_id;


-- A6. What was the maximum number of pizzas delivered in a single order?

SELECT order_id, (COUNT(*)) FROM customer_orders GROUP BY order_id ORDER BY count DESC LIMIT 1;


-- A7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT customer_id, 
	SUM(
		CASE 
			WHEN (extras IS NOT NULL)
			  OR  (exclusions IS NOT NULL)
			THEN 1 ELSE 0
		END 
	) AS Change,
	
	SUM(
		CASE 
			WHEN (extras IS NULL)
			  AND  (exclusions IS NULL)
			THEN 1 ELSE 0
		END 
	) AS NoChange
FROM customer_orders
JOIN runner_orders USING(order_id) WHERE cancellation IS NULL
GROUP BY customer_id;

-- A8. How many pizzas were delivered that had both exclusions and extras?
SELECT 
	COUNT(*) 
FROM 
	customer_orders 
WHERE 
	extras IS NOT NULL AND exclusions IS NOT NULL;


-- A9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
	EXTRACT(DAY FROM order_time) AS Day, EXTRACT(HOUR FROM order_time) AS Hour, COUNT(*)
FROM 
	customer_orders
GROUP BY 
	EXTRACT(DAY FROM order_time), EXTRACT(HOUR FROM order_time)
	
	
-- A10. What was the volume of orders for each day of the week?
SELECT 
	EXTRACT(WEEK FROM order_time) AS Week, EXTRACT(DOW FROM order_time) AS DayOfWeek, COUNT(*)
FROM 
	customer_orders
GROUP BY 
	EXTRACT(WEEK FROM order_time), EXTRACT(DOW FROM order_time);
	



								-- B. Runner and Customer Experience
								
								
-- B1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01) haveToComplete
SELECT 
	runner_id, EXTRACT(WEEK FROM registration_date), registration_date AS Week 
FROM 
	runners 


-- B2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT 
	runner_id, 
	ROUND(AVG(EXTRACT(MINUTE FROM (CAST(pickup_time AS TIMESTAMP) - CAST(order_time AS TIMESTAMP)))), 2) AS avgMinute
FROM 
	customer_orders JOIN runner_orders USING(order_id)
WHERE 
	pickup_time <> 'null'
GROUP BY 
	runner_id;


-- B3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT 
	customer_orders.pizza_id, 
	EXTRACT(MINUTE FROM (CAST(pickup_time AS TIMESTAMP) - CAST(order_time AS TIMESTAMP)))
FROM 
	customer_orders 
JOIN 
	runner_orders USING(order_id)
WHERE 
	pickup_time IS NOT NULL 
ORDER BY 
	customer_orders.pizza_id


-- B4. What was the average distance travelled for each customer?

SELECT 
	customer_id, AVG(CAST(distance AS FLOAT)) 
FROM 
	runner_orders 
JOIN 
	customer_orders USING(order_id) 
GROUP BY 
	customer_id;


-- B5. What was the difference between the longest and shortest delivery times for all orders?

SELECT 
	MAX(EXTRACT(MINUTE FROM CAST(pickup_time AS TIMESTAMP) - CAST(order_time AS TIMESTAMP)) + CAST(duration AS INT)) - 
	MIN(EXTRACT(MINUTE FROM CAST(pickup_time AS TIMESTAMP) - CAST(order_time AS TIMESTAMP)) + CAST(duration AS INT))
FROM 
	customer_orders
JOIN 
	runner_orders USING(order_id) 
WHERE 
	pickup_time IS NOT NULL;


-- B6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
	runner_id, pizza_id, AVG(CAST(duration AS INT))
FROM 
	runner_orders
JOIN 
	customer_orders USING(order_id)
GROUP BY 
	runner_id, pizza_id


-- B7. What is the successful delivery percentage for each runner?

SELECT runner_id,
	ROUND(SUM(CASE
		WHEN cancellation IS NOT NULL THEN 1 ELSE 0
	END)*100./ COUNT(*), 2)
FROM runner_orders
GROUP BY runner_id;



									-- C. Ingredient Optimisation
									
-- C1. What are the standard ingredients for each pizza?  

SELECT 
	pizza_id, a.topping_id, topping_name 
FROM 
	(
		SELECT 
			pizza_id, CAST(UNNEST(STRING_TO_ARRAY(toppings, ',')) AS INT) AS topping_id 
		FROM 
			pizza_recipes
	) AS a
JOIN 
	pizza_toppings USING(topping_id)
ORDER BY 
	pizza_id, a.topping_id


-- C2. What was the most commonly added extra?

SELECT 
	UNNEST(STRING_TO_ARRAY(extras, ',')) AS extra_ing, COUNT(*) AS numberOfTimeAdded 
FROM 
	customer_orders 
WHERE 
	extras IS NOT NULL
GROUP BY 
	extra_ing
ORDER BY 
	numberOfTimeAdded DESC 
LIMIT 1;


-- C3. What was the most common exclusion?

SELECT 
	UNNEST(STRING_TO_ARRAY(exclusions, ',')) AS exclusion_ing, COUNT(*) AS numberOfTimeExcluded 
FROM 
	customer_orders 
WHERE 
	exclusions IS NOT NULL
GROUP BY 
	exclusion_ing
ORDER BY 
	numberOfTimeExcluded DESC 
LIMIT 1;

-- C4. Generate an order item for each record in the customers_orders table in the format of one of the following: haveToComplete
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

SELECT * FROM customer_orders;

SELECT * FROM pizza_toppings;

-- C5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"


-- C6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?+

SELECT 	
	ingredient, COUNT(*) AS numberOfTimeUsed
FROM 
	(
	SELECT 
		pizza_id, *,  UNNEST(STRING_TO_ARRAY(CONCAT(toppings, ',', extras), ',')) AS ingredient FROM customer_orders
	JOIN 
		pizza_recipes USING(pizza_id)
	) AS a
WHERE 
	ingredient <> ''
GROUP BY 
	ingredient
ORDER BY
	numberOfTimeUsed DESC



	
						-- D. Pricing and Ratings

-- D1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
-- how much money has Pizza Runner made so far if there are no delivery fees?

SELECT
	SUM(CASE
		WHEN pizza_name = 'Meatlovers' THEN 12
		ELSE 10
	END) AS totalMoney
FROM customer_orders
JOIN 
	pizza_names USING(pizza_id)
JOIN 
	runner_orders USING(order_id)
WHERE cancellation IS NOT NULL


SELECT * FROM runner_orders;

-- D2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra

SELECT 
	SUM(CASE
			WHEN extras LIKE '%4%' THEN 1
			WHEN LENGTH(extras) >= 1 AND extras <> '4' THEN 1
			ELSE 0
	END) AS additional
FROM 
	customer_orders
WHERE 
	extras IS NOT NULL;

SELECT * FROM customer_orders;

-- D3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

-- D4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas

-- D5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?	
	
	