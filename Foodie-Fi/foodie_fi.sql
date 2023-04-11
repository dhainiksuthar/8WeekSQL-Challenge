SET SEARCH_PATH =  foodie_fi;

											-- A. Customer Journey
											
-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

-- Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

SELECT *
FROM SUBSCRIPTIONS S
JOIN PLANS P ON S.PLAN_ID = P.PLAN_ID
ORDER BY CUSTOMER_ID, S.PLAN_ID

-- customer 1 started from 1 jan 2008 by trial plan after completing trial plan he takes basec monthly plan
-- customer 2 started from 20 sep 2020 by trial plan then after he takes pro annual plan
-- customer 3 started from 13 jan 2008 by trial plan after completing trial plan he takes basec monthly plan
-- customer 4 take free trial plan from 17 jan after completing free trial he takes basic monthly then after using 3 month he churned his plan 

									-- B. Data Analysis Questions
									
-- B1.How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions;

SELECT * FROM plans;

SELECT * FROM subscriptions;

-- B2.What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT EXTRACT(YEAR FROM start_date), EXTRACT(MONTH FROM start_date), COUNT(*) FROM subscriptions AS s
LEFT JOIN plans p ON s.plan_id = p.plan_id
GROUP BY EXTRACT(YEAR FROM start_date), EXTRACT(MONTH FROM start_date)
ORDER BY EXTRACT(YEAR FROM start_date), EXTRACT(MONTH FROM start_date)


-- B3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT EXTRACT(MONTH FROM start_date), COUNT(*) FROM subscriptions AS s
LEFT JOIN plans p ON s.plan_id = p.plan_id
WHERE EXTRACT(YEAR FROM start_date) > 2020
GROUP BY EXTRACT(MONTH FROM start_date)
ORDER BY  EXTRACT(MONTH FROM start_date)

-- B4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT 
	ROUND(
	SUM(CASE
		WHEN p.plan_name = 'churn' THEN 1
		ELSE 0
	END) * 100.0/COUNT(*), 1)
	FROM subscriptions s
LEFT JOIN plans p ON s.plan_id = p.plan_id

-- B5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH cte1 AS(
SELECT s.customer_id, s.plan_id, p.plan_name, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY s.plan_id)
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id)

SELECT
	COUNT(*) AS churn_count,
	ROUND(100.0 * COUNT(*)/ (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 2)
FROM cte1
WHERE cte1.plan_id = 4
AND row_number = 2


-- B6. What is the number and percentage of customer plans after their initial free trial?

WITH cte1 AS(
	SELECT 
		customer_id, s.plan_id, plan_name, LEAD(plan_name, 1) OVER(PARTITION BY customer_id ORDER BY s.plan_id) 
	FROM 
		subscriptions s
	JOIN 
		plans p ON s.plan_id = p.plan_id
)

SELECT 
	lead AS plan_name, COUNT(*), ROUND(COUNT(*)*100.0 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions) , 2) AS percentage
FROM 
	cte1
WHERE 
	plan_id = 0 AND lead IS NOT NULL
GROUP BY 
	lead


-- B7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

SELECT 
	plan_name, 100.0 * COUNT(DISTINCT customer_id)/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions WHERE start_date <= '2020-12-31')
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE start_date <= '2020-12-31'
GROUP BY plan_name


-- B8. How many customers have upgraded to an annual plan in 2020?

SELECT plan_name, COUNT(*) FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE plan_name = 'pro annual' AND EXTRACT(YEAR FROM start_date) = 2020
GROUP BY plan_name;

-- B9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH cte AS(
SELECT customer_id, start_date FROM subscriptions s
WHERE s.plan_id = 0
)

SELECT AVG(s.start_date - cte.start_date)
FROM 
subscriptions s
JOIN cte ON cte.customer_id = s.customer_id
WHERE s.plan_id = 3

-- Using Self join

SELECT plan_id, ROUND(AVG(s.start_date - t.start_date), 0) AS Average_Days
FROM subscriptions s
JOIN (
	SELECT customer_id, start_date 
	FROM subscriptions
	WHERE plan_id = 0
	) AS t ON s.customer_id = t.customer_id
WHERE plan_id = 3
GROUP BY plan_id



-- B10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

WITH cte AS(
	SELECT 
	CASE
        WHEN s.start_date - t.start_date < 31 THEN '0-30 days'
        WHEN s.start_date - t.start_date BETWEEN 31
        AND 60 THEN '31-60 days'
        WHEN s.start_date - t.start_date BETWEEN 61
        AND 90 THEN '61-90 days'
        WHEN s.start_date - t.start_date BETWEEN 91
        AND 120 THEN '91-120 days'
        WHEN s.start_date - t.start_date BETWEEN 121
        AND 150 THEN '121-150 days'
        WHEN s.start_date - t.start_date BETWEEN 151
        AND 180 THEN '151-180 days'
        WHEN s.start_date - t.start_date BETWEEN 181
        AND 210 THEN '181-210 days'
        WHEN s.start_date - t.start_date BETWEEN 211
        AND 240 THEN '211-240 days'
        WHEN s.start_date - t.start_date BETWEEN 241
        AND 270 THEN '241-270 days'
        WHEN s.start_date - t.start_date BETWEEN 271
        AND 300 THEN '271-300 days'
        WHEN s.start_date - t.start_date BETWEEN 301
        AND 330 THEN '301-330 days'
        WHEN s.start_date - t.start_date BETWEEN 331
        AND 360 THEN '331-360 days'
        WHEN s.start_date - t.start_date > 360 THEN '360+ days' 
      END AS group_by_days_to_upgrade,
	COUNT(*) AS Count,
	ROUND(AVG(s.start_date - t.start_date), 0) AS Average_Days
	FROM subscriptions s
	JOIN (
		SELECT customer_id, start_date 
		FROM subscriptions
		WHERE plan_id = 0
		) AS t ON s.customer_id = t.customer_id
	WHERE plan_id = 3
	GROUP BY plan_id, group_by_days_to_upgrade
)

SELECT * FROM cte ORDER BY SPLIT_PART(group_by_days_to_upgrade, '-', 1)::INT

-- B11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

SELECT COUNT(*) FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
JOIN(
	SELECT customer_id, start_date
	FROM subscriptions inners
	JOIN plans innerp ON inners.plan_id = innerp.plan_id
	WHERE 
		start_date BETWEEN '2020-01-01' AND '2020-12-31' AND 
		innerp.plan_name = 'basic monthly'
	) AS t ON s.customer_id = t.customer_id
WHERE p.plan_name = 'pro monthly'
AND s.start_date < t.start_date
AND s.start_date BETWEEN '2020-01-01' AND '2020-12-31'



							-- C. Challenge Payment Question
-- C1. The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table 
-- with the following requirements:

-- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-- once a customer churns they will no longer make payments
-- Example outputs for this table might look like the following:

-- customer_id	plan_id	plan_name	payment_date	amount	payment_order

WITH cte1 AS(
	SELECT customer_id, plan_id, start_date, 
	LEAD(start_date) OVER(PARTITION BY customer_id ORDER BY start_date) AS next_start_date
	FROM
		subscriptions
	WHERE plan_id <> 0
),
cte2 AS(
SELECT *, 
	GENERATE_SERIES(start_date, 
					CASE
						WHEN plan_id = 4 THEN NULL
						ELSE COALESCE(next_start_date - INTERVAL '1 DAY', '2020-12-31'::DATE) 
					END
					,
					CASE
						WHEN plan_id = 3 THEN INTERVAL '1 YEAR'
						ELSE INTERVAL '1 MONTH'
					END
				   ) :: DATE
FROM 
	cte1
),

cte3 AS(
SELECT cte2.plan_id, customer_id, generate_series, plan_name, price,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY generate_series),
	LAG(cte2.plan_id) OVER(PARTITION BY customer_id ORDER BY start_date) AS prev_plan_id,
	LAG(price) OVER(PARTITION BY customer_id ORDER BY start_date) AS prev_price
FROM cte2
JOIN plans p ON cte2.plan_id = p.plan_id
WHERE generate_series <= '2020-12-31' :: DATE
)

SELECT customer_id, plan_id, plan_name, generate_series AS payment_date, 
	CASE
		WHEN plan_id IN (2, 3) AND prev_plan_id = 1 THEN price - prev_price
		ELSE price
	END AS amount,
	row_number AS payment_order
FROM
	cte3
ORDER BY customer_id;


								-- D. Outside The Box Questions
-- The following are open ended questions which might be asked during a technical interview for this case study - there are no right or wrong answers, 
-- but answers that make sense from both a technical and a business perspective make an amazing impression!

-- D1. How would you calculate the rate of growth for Foodie-Fi?

WITH cte1 AS(
	SELECT 
		EXTRACT(YEAR FROM start_date) AS year, EXTRACT(MONTH FROM start_date) AS month, COUNT(*) 
	FROM subscriptions
	GROUP BY year, month
	ORDER BY year, month
),

cte2 AS(
	SELECT *, LAG(count) OVER(ORDER BY year, month)
	FROM cte1
)

SELECT YEAR,
	MONTH,
	COUNT AS CURRENT_NUM_OF_CUST,
	LAG AS PREV_MONTHS_NUM_OF_CUST,
	ROUND(COUNT*100.0 / LAG - 100,
		0) AS PERCENTAGE_GROWTH_FROM_PREV_MONTH
FROM CTE2;


-- D2. What key metrics would you recommend Foodie-Fi management to track over time to assess performance of their overall business?

WITH cte1 AS(
	SELECT 
		EXTRACT(YEAR FROM start_date) AS year, EXTRACT(MONTH FROM start_date) AS month, COUNT(*) 
	FROM subscriptions
	GROUP BY year, month
	ORDER BY year, month
)

SELECT 
	year, month, count AS current_num_of_cust 
FROM cte1;

-- D3. What are some key customer journeys or experiences that you would analyse further to improve customer retention?
WITH cte
AS (
	SELECT
		s.customer_id,
		p.plan_id,
		p.plan_name,
		start_date,
		LEAD(p.plan_id) OVER(
			PARTITION BY customer_id ORDER BY p.plan_id) plan_n
	FROM subscriptions s
	JOIN plans p
	ON p.plan_id = s.plan_id)

SELECT 
	plan_id,
	COUNT(*) churn_counts
FROM cte
WHERE plan_n = 4
GROUP BY plan_id;



-- D4. If the Foodie-Fi team were to create an exit survey shown to customers who wish to cancel their subscription, what questions would you include in the survey?
-- What were the trigger(s) that made you cancel?
-- What did you like about the product or service?
-- What didnt you like about the product or service?
-- What suggestions do you have to improve the product or service?
-- What suggestions do you have to improve the product or service?Would you reconsider our product in the future? What would that take?
-- Who do you think is the ideal customer for our product or service?


-- D5. What business levers could the Foodie-Fi team use to reduce the customer churn rate? How would you validate the effectiveness of your ideas?
-- From the data we have seen ~250 customers have upgraded thier plan to annual one and only ~5-10 customers have opted outfrom the annual plan
-- which is bit positive side, So problem have arised in monthly plan and trial plans,
-- If we talk about monthly plan particulaly pro monthly so there is hardly a price difference between pro monthly to pro annualy so they can 
-- set service pricing to make customers can opt for longer term plan but this is just one aspect but from trial - churn and basic - churn rate
-- we can see customers are lefting subscriptions which is 20% of total, company might need to improve effectiveness of their service and make customers 
-- feel worth of the value that service provides.
-- To talk about measuring effectiveness we could use various metrics such as churn ratio for each plan, customer plan upgradation growth monthly or quaterly.





