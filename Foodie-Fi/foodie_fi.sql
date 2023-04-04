SET SEARCH_PATH =  foodie_fi;


									-- B. Data Analysis Questions
									
-- How many customers has Foodie-Fi ever had?

SELECT COUNT(DISTINCT(customer_id)) FROM subscriptions;

SELECT * FROM plans;

SELECT * FROM subscriptions;

-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value

SELECT EXTRACT(YEAR FROM start_date), EXTRACT(MONTH FROM start_date), COUNT(*) FROM subscriptions AS s
LEFT JOIN plans p ON s.plan_id = p.plan_id
GROUP BY EXTRACT(YEAR FROM start_date), EXTRACT(MONTH FROM start_date)
ORDER BY EXTRACT(YEAR FROM start_date), EXTRACT(MONTH FROM start_date)


-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT EXTRACT(MONTH FROM start_date), COUNT(*) FROM subscriptions AS s
LEFT JOIN plans p ON s.plan_id = p.plan_id
WHERE EXTRACT(YEAR FROM start_date) > 2020
GROUP BY EXTRACT(MONTH FROM start_date)
ORDER BY  EXTRACT(MONTH FROM start_date)

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

SELECT 
	ROUND(
	SUM(CASE
		WHEN p.plan_name = 'churn' THEN 1
		ELSE 0
	END) * 100.0/COUNT(*), 1)
	FROM subscriptions s
LEFT JOIN plans p ON s.plan_id = p.plan_id

-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

SELECT * FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id

-- What is the number and percentage of customer plans after their initial free trial?
-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
-- How many customers have upgraded to an annual plan in 2020?
-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
