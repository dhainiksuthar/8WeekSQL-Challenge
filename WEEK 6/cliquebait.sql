										--B. Digital Analysis

--Using the available datasets - answer the following questions using a single query for each one:

-- 1. How many users are there?
SELECT 
	COUNT(DISTINCT user_id) 
FROM clique_bait.users;

-- 2. How many cookies does each user have on average?
WITH cte1 AS(
SELECT COUNT(*) AS count FROM clique_bait.users 
GROUP BY user_id
)

SELECT AVG(count) FROM cte1;


-- 3. What is the unique number of visits by all users per month?

SELECT 
	DATEPART(MONTH, event_time) AS Month, COUNT(DISTINCT visit_id) visitCount
FROM clique_bait.events
GROUP BY DATEPART(MONTH, event_time)
ORDER BY Month

-- 4. What is the number of events for each event type?

SELECT event_name, COUNT(*) AS countOfEvent FROM clique_bait.events e1
LEFT JOIN clique_bait.event_identifier e2 ON e1.event_type = e2.event_type
GROUP BY event_name;


-- 5. What is the percentage of visits which have a purchase event?

WITH cte1 AS(
	SELECT event_name, COUNT(DISTINCT visit_id) AS countOfEvent FROM clique_bait.events e1
	LEFT JOIN clique_bait.event_identifier e2 ON e1.event_type = e2.event_type
	GROUP BY event_name
)
SELECT 
	CAST(countOfEvent*100.0/(SELECT COUNT(DISTINCT visit_id) FROM clique_bait.events) AS DECIMAL(4,2)) AS Purchase_Percentage
FROM cte1
WHERE event_name = 'Purchase';


-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?

SELECT 
	CAST(COUNT(DISTINCT visit_id)*100/(SELECT COUNT(DISTINCT visit_id) FROM clique_bait.events) AS DECIMAL(4, 2)) AS perecentage_of_checkout_not_purchase
FROM clique_bait.events e
LEFT JOIN clique_bait.event_identifier ei ON e.event_type = ei.event_type
LEFT JOIN clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
WHERE ei.event_name <> 'Purchase' AND ph.page_name = 'Checkout' AND ei.event_name = 'Page View'


-- 7. What are the top 3 pages by number of views?

SELECT page_name, COUNT(*) as page_name_count
FROM clique_bait.events e
LEFT JOIN clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
GROUP BY page_name
ORDER BY page_name_count DESC
OFFSET 0 ROWS FETCH FIRST 3 ROWS ONLY;


-- 8. What is the number of views and cart adds for each product category?

SELECT ph.product_category,
	SUM(
		CASE WHEN ei.event_name = 'Page View' THEN 1 ELSE 0 END) AS page_views,
	SUM(CASE WHEN ei.event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS cart_adds
FROM clique_bait.events e
LEFT JOIN clique_bait.event_identifier ei ON e.event_type = ei.event_type
LEFT JOIN clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
WHERE ph.product_category IS NOT NULL
GROUP BY ph.product_category 


-- 9. What are the top 3 products by purchases?

SELECT TOP 3
	page_name, COUNT(*) AS count
FROM clique_bait.events AS e
JOIN clique_bait.page_hierarchy AS ph ON e.page_id = ph.page_id
JOIN clique_bait.event_identifier AS ei ON e.event_type = ei.event_type
WHERE event_name = 'Add to Cart' AND visit_id IN (
			SELECT visit_id  FROM clique_bait.events AS e
			JOIN clique_bait.event_identifier AS ei ON e.event_type = ei.event_type
			WHERE ei.event_name = 'Purchase')
GROUP BY page_name
ORDER BY count DESC;


										--3. Product Funnel Analysis
--Using a single SQL query - create a new output table which has the following details:

--How many times was each product viewed?
--How many times was each product added to cart?
--How many times was each product added to a cart but not purchased (abandoned)?
--How many times was each product purchased?
--Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

WITH cte1 AS(
SELECT page_name,
		SUM(CASE
			WHEN event_name = 'Page View' AND product_id IS NOT NULL THEN 1 ELSE 0 END) AS views,
		SUM(CASE
			WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS add_to_cart
FROM clique_bait.events AS e
JOIN clique_bait.event_identifier AS ei ON e.event_type = ei.event_type
JOIN clique_bait.page_hierarchy AS ph ON e.page_id = ph.page_id
GROUP BY page_name),

cte2 AS(
	SELECT page_name, COUNT(*) as carted_but_not_purchased
	FROM clique_bait.events AS e
	JOIN clique_bait.event_identifier AS ei ON e.event_type = ei.event_type
	JOIN clique_bait.page_hierarchy AS ph ON e.page_id = ph.page_id
	WHERE event_name = 'Add to Cart' AND visit_id NOT IN 
								(SELECT 
									visit_id 
									FROM clique_bait.events e
									JOIN clique_bait.event_identifier AS ei ON e.event_type = ei.event_type 
									WHERE event_name = 'Purchase'
								)
	GROUP BY page_name
)


SELECT 
	cte1.page_name, 
	views, 
	add_to_cart, 
	carted_but_not_purchased, 
	add_to_cart - carted_but_not_purchased AS purchased
INTO #product_details
FROM cte1 
JOIN cte2 ON cte1.page_name = cte2.page_name;
GO

SELECT * FROM #product_details;

SELECT 
	product_category,
	sum(p.views) [view],
	sum(add_to_cart) add_to_cart,
	sum(carted_but_not_purchased) carted_but_not_purchased,
	sum(purchased) purchased
	INTO #product_category_details
FROM #product_details p
JOIN clique_bait.page_hierarchy ph
ON p.page_name = ph.page_name
GROUP BY product_category;
GO

SELECT * FROM #product_category_details;


--Use your 2 new output tables - answer the following questions:

--Which product had the most views, cart adds and purchases?

WITH cte1 AS(
	SELECT 
		page_name,
		RANK() OVER(ORDER BY views DESC) views_rank,
		RANK() OVER(ORDER BY add_to_cart DESC) cart_rank,
		RANK() OVER(ORDER BY purchased DESC) purchase_rank
	FROM #product_details
)
SELECT page_name,
	'most_viewed' AS Product
FROM cte1
WHERE views_rank = 1
UNION
SELECT page_name,
	'most_carted' AS Product
FROM cte1
WHERE cart_rank = 1
UNION
SELECT page_name,
	'most_purchased' AS Product
FROM cte1
WHERE purchase_rank = 1

--Which product was most likely to be abandoned?

WITH cte1 AS(
	SELECT page_name, RANK() OVER(ORDER BY carted_but_not_purchased DESC) AS ran
	FROM #product_details
)
SELECT page_name 
FROM cte1 WHERE ran = 1

--Which product had the highest view to purchase percentage?

SELECT TOP 1 page_name, CAST(purchased*100.0/views AS DECIMAL(4,2)) AS Percentage FROM #product_details
ORDER BY Percentage DESC

--What is the average conversion rate from view to cart add?

SELECT CAST(AVG(add_to_cart*100.0/views) AS DECIMAL(4,2)) AS avg_view_cart_percentage
FROM #product_details

--What is the average conversion rate from cart add to purchase?

SELECT CAST(AVG(purchased*100.0/add_to_cart) AS DECIMAL(4,2)) AS avg_cart_purchase_percentage
FROM #product_details


										--3. Campaigns Analysis
--Generate a table that has 1 single row for every unique visit_id record and has the following columns:

--user_id
--visit_id
--visit_start_time: the earliest event_time for each visit
--page_views: count of page views for each visit
--cart_adds: count of product cart add events for each visit
--purchase: 1/0 flag if a purchase event exists for each visit
--campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
--impression: count of ad impressions for each visit
--click: count of ad clicks for each visit
--(Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)
--Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.


SELECT 
	visit_id, u.user_id, c.campaign_name,
	MIN(event_time) AS visit_start_time, 
	SUM(CASE WHEN event_name = 'Page View' THEN 1 ELSE 0 END) AS page_view,
	SUM(CASE WHEN event_name = 'Add to Cart' THEN 1 ELSE 0 END) AS add_to_cart,
	SUM(CASE WHEN event_name = 'Purchase' THEN 1 ELSE 0 END) AS Purchase,
	SUM(CASE WHEN event_name = 'Ad Imporession' THEN 1 ELSE 0 END) AS ad_impression,
	SUM(CASE WHEN event_name = 'Ad Click' THEN 1 ELSE 0 END) AS click,
	STRING_AGG(CASE WHEN event_name = 'Add to Cart' THEN page_name END , ' ')
FROM clique_bait.events e
JOIN clique_bait.event_identifier AS ei ON e.event_type = ei.event_type
JOIN clique_bait.page_hierarchy AS ph ON e.page_id = ph.page_id
LEFT JOIN clique_bait.campaign_identifier c ON event_time BETWEEN c.start_date AND c.end_date
LEFT JOIN clique_bait.users u ON e.cookie_id = u.cookie_id
GROUP BY visit_id, u.user_id, c.campaign_name;

--Some ideas you might want to investigate further include:

--Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
--Does clicking on an impression lead to higher purchase rates?
--What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
--What metrics can you use to quantify the success or failure of each campaign compared to eachother?



SELECT *
FROM clique_bait.events AS e
JOIN clique_bait.event_identifier AS ei ON e.event_type = ei.event_type
JOIN clique_bait.page_hierarchy AS ph ON e.page_id = ph.page_id



SELECT * FROM clique_bait.events

SELECT * FROM clique_bait.event_identifier

SELECT * FROM clique_bait.page_hierarchy

SELECT * FROM clique_bait.campaign_identifier

SELECT * FROM clique_bait.users
