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

ALTER TABLE runner_orders
ALTER COLUMN pickup_time TYPE TIMESTAMP
USING pickup_time :: TIMESTAMP

ALTER TABLE runner_orders
ALTER COLUMN duration TYPE INT
USING duration :: INT;

ALTER TABLE runner_orders
ALTER COLUMN distance TYPE NUMERIC
USING distance :: NUMERIC;

SELECT * FROM pizza_recipes;


-- A. Pizza Metrics
-- A1. How many pizzas were ordered?

SELECT 
	COUNT(order_id) 
FROM 
	customer_orders;


-- A2. How many unique customer orders were made?

SELECT 
	COUNT(DISTINCT(order_id)) 
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
	pn.pizza_name, COUNT(*) 
FROM 
	customer_orders AS co
INNER JOIN
	runner_orders ro ON co.order_id = ro.order_id AND ro.cancellation IS NULL
INNER JOIN 
	pizza_names pn ON co.pizza_id = pn.pizza_id
GROUP BY 
	pizza_name;

-- A5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT customer_id, pizza_name, COUNT(*)
FROM pizza_names JOIN customer_orders USING(pizza_id) GROUP BY customer_id, pizza_name
order by customer_id;

-- A6. What was the maximum number of pizzas delivered in a single order?

SELECT 
	order_id, (COUNT(*)) 
FROM 
	customer_orders 
GROUP BY 
	order_id 
ORDER BY 
	count DESC 
LIMIT 1;


-- A7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- Doubt
SELECT customer_id, 
	SUM(
		CASE 
			WHEN extras IS NOT NULL OR exclusions IS NOT NULL
			THEN 1 ELSE 0
		END 
	) AS toppings_changed,
	
	SUM(
		CASE 
			WHEN (extras IS NULL)
			  AND  (exclusions IS NULL)
			THEN 1 ELSE 0
		END 
	) AS topings_not_changed
FROM customer_orders
JOIN runner_orders USING(order_id) WHERE cancellation IS NULL
GROUP BY customer_id;

-- A8. How many pizzas were delivered that had both exclusions and extras?
SELECT 
	COUNT(*) 
FROM 
	customer_orders co
INNER JOIN runner_orders ro ON co.order_id = ro.order_id AND ro.cancellation IS NULL
WHERE 
	extras IS NOT NULL AND exclusions IS NOT NULL;


-- A9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
	EXTRACT(HOUR FROM order_time) AS Hour, COUNT(*)
FROM 
	customer_orders
GROUP BY 
	EXTRACT(HOUR FROM order_time)
	
	
-- A10. What was the volume of orders for each day of the week?
SELECT 
	EXTRACT(DOW FROM order_time) AS DayOfWeek, COUNT(*)
FROM 
	customer_orders
GROUP BY 
	EXTRACT(DOW FROM order_time);
	



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

SELECT num_of_pizza, FLOOR(AVG(avg_time_taken)) AS avg_total_time_taken, FLOOR(AVG(avg_time_taken)/num_of_pizza) AS avg_time_taken_per_pizza
FROM
	(
		SELECT 
			ro.order_id, COUNT(*) AS num_of_pizza, 
			AVG(EXTRACT(EPOCH FROM (pickup_time - order_time)))/60 AS avg_time_taken 
		FROM 
			runner_orders ro 
		JOIN 
			customer_orders co ON ro.order_id = co.order_id
		WHERE 
			cancellation IS NULL
		GROUP BY 
			ro.order_id
	) AS a
GROUP BY
	num_of_pizza;


-- B4. What was the average distance travelled for each customer?

SELECT 
	customer_id, ROUND(AVG(CAST(distance AS NUMERIC)), 2) 
FROM 
	runner_orders 
JOIN 
	customer_orders USING(order_id) 
GROUP BY 
	customer_id
ORDER BY customer_id;


-- B5. What was the difference between the longest and shortest delivery times for all orders?
SELECT 
	MAX(duration) AS max_delivery_time,
	MIN(duration) AS min_delivery_time,
	MAX(duration) - MIN(duration) AS time_difference
FROM 
	runner_orders


-- B6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
	runner_id, distance, duration, ROUND(distance/duration * 60, 2) AS speed_KMPH	
FROM runner_orders
WHERE
	cancellation IS NULL
ORDER BY
	runner_id, speed_KMPH;


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
	pizza_name, STRING_AGG(topping_name, ', ') 
FROM 
	(
		SELECT 
			pizza_id, UNNEST(STRING_TO_ARRAY(toppings, ',')) as topping_id 
		FROM pizza_recipes pr
	) AS a 
JOIN 
	pizza_toppings pt ON a.topping_id :: INT = pt.topping_id
JOIN 
	pizza_names pn ON a.pizza_id = pn.pizza_id
GROUP BY 
	pizza_name;


-- C2. What was the most commonly added extra?
SELECT 
	topping_id, numberoftimeadded, topping_name 
FROM 
	(
		SELECT 
			UNNEST(STRING_TO_ARRAY(extras, ',')) AS extra_ing, COUNT(*) AS numberOfTimeAdded 
		FROM 
			customer_orders co
		WHERE 
			extras IS NOT NULL
		GROUP BY 
			extra_ing
		ORDER BY 
			numberOfTimeAdded DESC 
	) AS co
JOIN pizza_toppings pt ON pt.topping_id = co.extra_ing :: INT

-- C3. What was the most common exclusion?
SELECT 
	topping_name AS excluded_ingredient, numberoftimeexcluded
FROM
	(
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
	LIMIT 1
	) a
JOIN 
	pizza_toppings pt ON a.exclusion_ing :: INT = pt.topping_id

-- C4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH cte1 AS
	(
		SELECT order_id, pizza_id, UNNEST(STRING_TO_ARRAY(exclusions, ',')) :: INT AS exclusion_id,
		UNNEST(STRING_TO_ARRAY(extras, ',')) :: INT AS extras_id
		FROM customer_orders
	),
cte2 AS
	(
	SELECT 
		cte1.order_id, cte1.pizza_id, 
		CONCAT(
			CASE 
				WHEN STRING_AGG(pt1.topping_name, ',') IS NOT NULL THEN CONCAT('Excluded ', STRING_AGG(pt1.topping_name, ','))
				ELSE NULL
			END , '  ',
			CASE
				WHEN STRING_AGG(pt2.topping_name, ',') IS NOT NULL THEN CONCAT('Extra ', STRING_AGG(pt2.topping_name, ','))
				ELSE NULL
			END
			) AS ext_exc_name 
	FROM cte1
	LEFT JOIN pizza_toppings pt1 ON exclusion_id = pt1.topping_id
	LEFT JOIN pizza_toppings pt2 ON extras_id = pt2.topping_id
	GROUP BY order_id, pizza_id
	),
cte3 AS(
	SELECT * FROM cte2
	UNION
	SELECT order_id, pizza_id, extras 
	FROM customer_orders 
	WHERE extras IS NULL AND exclusions IS NULL
)

SELECT order_id, 
	CASE
		WHEN ext_exc_name IS NOT NULL THEN CONCAT(pizza_name,' - ', ext_exc_name)
		ELSE pizza_name
	END AS pizza_details
FROM cte3
LEFT JOIN pizza_names pn ON cte3.pizza_id = pn.pizza_id
ORDER BY order_id;


-- C5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH cte1 AS
	(
	SELECT co.order_id, co.pizza_id, pn.pizza_name, UNNEST(STRING_TO_ARRAY(pr.toppings, ',')) :: INT AS topping_id FROM customer_orders co
	LEFT JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
	LEFT JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
	ORDER BY order_id, topping_id	
	)

SELECT cte1.order_id, cte1.pizza_id, MIN(pizza_name), STRING_AGG(topping_name, ',') as all_topping FROM cte1 
LEFT JOIN pizza_toppings pt ON cte1.topping_id = pt.topping_id
GROUP BY order_id, pizza_id 






SELECT * FROM pizza_toppings;

-- C6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?+
SELECT 
	pt.topping_name, numberoftimeused 
FROM
	(
	SELECT 	
		ingredient, COUNT(*) AS numberOfTimeUsed
	FROM 
		(
		SELECT 
			pizza_id, *,  UNNEST(STRING_TO_ARRAY(CONCAT(toppings, ',', extras), ',')) AS ingredient 
		FROM 
			customer_orders
		JOIN 
			pizza_recipes USING(pizza_id)
		) AS a
	WHERE 
		ingredient <> ''
	GROUP BY 
		ingredient
	) a 
JOIN 
	pizza_toppings pt ON a.ingredient :: INT = pt.topping_id
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
WHERE cancellation IS NULL


-- D2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra

SELECT 
	SUM(CASE
			WHEN extras LIKE '%4%' THEN 1
			WHEN LENGTH(extras) >= 1 AND extras <> '4' THEN 1
			ELSE 0
	END) + 
	SUM(CASE
		WHEN pizza_name = 'Meatlovers' THEN 12
		ELSE 10
	END) AS totalMoney
FROM 
	customer_orders
JOIN 
	pizza_names USING(pizza_id)
JOIN 
	runner_orders USING(order_id)
WHERE cancellation IS NULL


-- D3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
-- how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data 
-- for ratings for each successful customer order between 1 to 5.

CREATE SCHEMA ratings;

ALTER TABLE runner_orders
ADD CONSTRAINT unique_order_id UNIQUE(order_id);


CREATE TABLE ratings.runner_rating(
	rating_id SERIAL PRIMARY KEY,
	order_id INT,
	rate INT CHECK(rate >= 1 AND rate <= 5),
	FOREIGN KEY(order_id) REFERENCES pizza_runner.runner_orders(order_id)
);

INSERT INTO 
	ratings.runner_rating(order_id, rate)
VALUES
	(1, 4),
    (2, 3),
	(3, 1),
    (4, 5);

SELECT * FROM ratings.runner_rating;

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

SELECT 
	customer_id, ro.order_id, ro.runner_id, rr.rate, order_time, pickup_time, 
	EXTRACT(MINUTE FROM pickup_time :: TIMESTAMP - order_time) AS timeBetweenOrderAndPickup, 
	duration, ROUND((distance::FLOAT / (duration::FLOAT / 60))::NUMERIC, 2) AS speedInKMPH,
	COUNT(*) OVER(PARTITION BY runner_id) AS TotalPizaaByRunnerID
FROM 
	runner_orders AS ro 
LEFT JOIN 
	ratings.runner_rating AS rr ON ro.order_id = rr.order_id 
JOIN 
	customer_orders AS co ON ro.order_id = co.order_id
WHERE 
	cancellation IS NULL;

-- D5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
-- how much money does Pizza Runner have left over after these deliveries?	

WITH cte1 AS(
SELECT ro.order_id,
	AVG(runner_id)::INT AS runner_id,
	SUM(CASE
		WHEN pizza_name = 'Meatlovers' THEN 12
		ELSE 10
	END) -
	ROUND(AVG(distance:: NUMERIC)  * 0.30, 2) AS left_over_money
FROM runner_orders AS ro JOIN customer_orders AS co ON ro.order_id = co.order_id
JOIN pizza_names AS pn ON co.pizza_id = pn.pizza_id
GROUP BY ro.order_id
ORDER BY ro.order_id)

SELECT sum(left_over_money) FROM cte1


								-- E. Bonus Questions
-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? 
-- Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

SELECT * FROM pizza_names

INSERT INTO pizza_names
VALUES(3, 'SupremeVilla');

INSERT INTO pizza_recipes
VALUES(3, '1,2,3,4,5,6,7,8,9,10,11,12');

SELECT
  *
FROM
  pizza_runner.pizza_names AS n
  JOIN pizza_runner.pizza_recipes AS r ON n.pizza_id = r.pizza_id

create or replace function array_diff(array1 anyarray, array2 anyarray)
returns anyarray language sql immutable as $$
    select coalesce(array_agg(elem), '{}')
    from unnest(array1) elem
    where elem <> all(array2)
$$;

WITH cte1 AS(
SELECT *, ROW_NUMBER() OVER(PARTITION BY order_id, pizza_id) AS row_ FROM customer_orders ORDER BY order_id),

cte2 AS(
SELECT order_id, cte1.pizza_id,row_, STRING_TO_ARRAY(exclusions, ', ') AS exclusions, STRING_TO_ARRAY(extras, ', ') as extras, STRING_TO_ARRAY(toppings, ', ') AS toppings FROM cte1
LEFT JOIN pizza_recipes AS pr ON cte1.pizza_id = pr.pizza_id),

cte3 AS(
SELECT order_id, pizza_id, row_, toppings, extras,
	CASE 
		WHEN exclusions IS NOT NULL THEN array_diff(toppings, exclusions)
		ELSE toppings
	END AS left_toppings
FROM cte2),

cte4 AS(
SELECT order_id, pizza_id, row_, toppings, extras, ARRAY_CAT(toppings, extras)
FROM cte3),

cte5 AS(
SELECT order_id, pizza_id, row_, UNNEST(array_cat) AS topping_id, COUNT(*)
FROM cte4
GROUP BY order_id, pizza_id, row_, topping_id),


cte6 AS(
SELECT order_id, pizza_id, row_,
	CASE
		WHEN count > 1 THEN STRING_AGG(CONCAT(count, topping_name), ', ')
		ELSE STRING_AGG(topping_name, ', ')
	END AS final_topping
FROM cte5
LEFT JOIN pizza_toppings pt ON cte5.topping_id :: INT = pt.topping_id
GROUP BY order_id, pizza_id, row_, count
),

cte7 AS(
SELECT order_id, cte6.pizza_id, row_, CONCAT(pizza_name,' - ', final_topping) AS final_topping FROM cte6
LEFT JOIN pizza_names pn ON cte6.pizza_id = pn.pizza_id
ORDER BY order_id)

SELECT order_id, pizza_id, row_, MAX(final_topping)
FROM cte7
GROUP BY order_id, pizza_id, row_



