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

SELECT ph.product_id, COUNT(*) as count_cart
FROM clique_bait.events e
LEFT JOIN clique_bait.event_identifier ei ON e.event_type = ei.event_type
LEFT JOIN clique_bait.page_hierarchy ph ON e.page_id = ph.page_id
WHERE event_name = 'Purchase'
GROUP BY ph.product_id


SELECT * FROM clique_bait.event_identifier

SELECT * FROM clique_bait.page_hierarchy