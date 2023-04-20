				-- A High Level Sales Analysis

-- A1. What was the total quantity sold for all products?

SELECT
	SUM(qty) AS sold_quantity
FROM
	balanced_tree.sales;


-- A2. What is the total generated revenue for all products before discounts?

SELECT
	SUM(qty*price) AS revenue
FROM
	balanced_tree.sales;


-- A3. What was the total discount amount for all products?

SELECT
	SUM(discount) AS total_discount
FROM
	balanced_tree.sales;


								-- B Transaction Analysis

-- B1. How many unique transactions were there?

SELECT 
	COUNT(DISTINCT txn_id) AS transaction_count 
FROM balanced_tree.sales;

-- B2. What is the average unique products purchased in each transaction?

WITH cte1 AS(
SELECT 
	COUNT(DISTINCT prod_id) AS avg_qty
FROM balanced_tree.sales
GROUP BY txn_id)

SELECT
	AVG(avg_qty) AS avg_qty
FROM
	cte1;

-- B3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?

WITH cte1 AS(
	SELECT
		CAST(SUM((100.0-discount)*qty*price/100.0) AS DECIMAL(10,2)) AS amount
	FROM 
		balanced_tree.sales
GROUP BY txn_id
)

SELECT
	PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY amount) OVER(PARTITION BY NULL) AS [25th_percentile],
	PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY amount) OVER(PARTITION BY NULL) AS [50th_percentile],
	PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY amount) OVER(PARTITION BY NULL) AS [75th_percentile]
FROM cte1;

-- B4. What is the average discount value per transaction?

SELECT
	txn_id, CAST(AVG((100.0-discount)*qty*price/100.0) AS DECIMAL(5,2)) AS avg_discount
FROM
	balanced_tree.sales
GROUP BY txn_id;

-- B5. What is the percentage split of all transactions for members vs non-members?
WITH cte1 AS(
	SELECT
		SUM(CASE WHEN member = 't' THEN 1 ELSE 0 END) AS member,
		SUM(CASE WHEN member = 'f' THEN 1 ELSE 0 END) AS nonmember
	FROM
		balanced_tree.sales
)

SELECT
	CAST(member*100.0/(nonmember+member) AS DECIMAL(4,2)) AS member_percentage,
	CAST(nonmember*100.0/(nonmember+member) AS DECIMAL(4,2)) AS member_percentage
FROM cte1;

-- B6. What is the average revenue for member transactions and non-member transactions?

WITH cte1 AS (
	SELECT txn_id, member,
		SUM( (100.0-discount)*qty*price/100.0 ) AS sum
	FROM balanced_tree.sales
	GROUP BY txn_id, member
)

SELECT 
	member, AVG(sum) AS avg_revenue 
FROM cte1
GROUP BY member;

									-- C Product Analysis

-- C1. What are the top 3 products by total revenue before discount?

SELECT TOP 3
	product_name, SUM(qty*s.price) AS revenue
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
GROUP BY product_name
ORDER BY revenue DESC;

-- C2. What is the total quantity, revenue and discount for each segment?

SELECT 
	segment_name, SUM(qty) AS quantity, SUM(qty*s.price) AS revenue, SUM(discount*qty*s.price/100.0) AS discount
FROM 
	balanced_tree.sales s
LEFT JOIN 
	balanced_tree.product_details p 
ON 
	s.prod_id = p.product_id
GROUP BY 
	segment_name
ORDER BY segment_name

-- C3. What is the top selling product for each segment?

WITH cte1 AS(
	SELECT 
		segment_name, product_name, SUM(qty) AS quantity, SUM(qty*s.price) AS revenue, SUM(discount*qty*s.price/100.0) AS discount
	FROM 
		balanced_tree.sales s
	LEFT JOIN 
		balanced_tree.product_details p 
	ON 
		s.prod_id = p.product_id
	GROUP BY 
		segment_name, product_name
)
SELECT *
FROM (
	SELECT *,
		RANK() OVER(PARTITION BY segment_name ORDER BY quantity DESC) as rank
	FROM cte1
) A
WHERE A.rank = 1;

-- C4. What is the total quantity, revenue and discount for each category?

SELECT 
	category_name, SUM(qty) AS quantity, SUM(qty*s.price) AS revenue, SUM(discount*qty*s.price/100.0) AS discount
FROM 
	balanced_tree.sales s
LEFT JOIN 
	balanced_tree.product_details p 
ON 
	s.prod_id = p.product_id
GROUP BY 
	category_name
ORDER BY category_name

-- C5. What is the top selling product for each category?

WITH cte1 AS(
	SELECT 
		category_name, product_name, SUM(qty) AS quantity, SUM(qty*s.price) AS revenue, SUM(discount*qty*s.price/100.0) AS discount
	FROM 
		balanced_tree.sales s
	LEFT JOIN 
		balanced_tree.product_details p 
	ON 
		s.prod_id = p.product_id
	GROUP BY 
		category_name, product_name
)
SELECT *
FROM (
	SELECT *,
		RANK() OVER(PARTITION BY category_name ORDER BY quantity DESC) as rank
	FROM cte1
) A
WHERE A.rank = 1;

-- C6. What is the percentage split of revenue by product for each segment?

WITH cte1 AS(
	SELECT 
		segment_name, product_name, SUM((100.0-discount)*qty*s.price) AS product_revenue
	FROM 
		balanced_tree.sales s
	LEFT JOIN 
		balanced_tree.product_details p 
	ON 
		s.prod_id = p.product_id
	GROUP BY 
		segment_name, product_name
),
cte2 AS(
	SELECT *,
		SUM(product_revenue) OVER(PARTITION BY segment_name) as segment_revenue
	FROM cte1
)
SELECT segment_name, product_name, 
	CAST(product_revenue*100.0/segment_revenue AS DECIMAL(4,2)) AS product_percentage
FROM cte2
ORDER BY segment_name, product_percentage DESC


-- C7. What is the percentage split of revenue by segment for each category?

WITH cte1 AS(
	SELECT 
		segment_name, category_name, SUM((100.0-discount)*qty*s.price) AS category_revenue
	FROM 
		balanced_tree.sales s
	LEFT JOIN 
		balanced_tree.product_details p 
	ON 
		s.prod_id = p.product_id
	GROUP BY 
		segment_name, category_name
),
cte2 AS(
	SELECT *,
		SUM(category_revenue) OVER(PARTITION BY category_name) as segment_revenue
	FROM cte1
)
SELECT segment_name, category_name, 
	CAST(category_revenue*100.0/segment_revenue AS DECIMAL(4,2)) AS category_percentage
FROM cte2
ORDER BY segment_name, category_percentage DESC

-- C8. What is the percentage split of total revenue by category?

SELECT category_name, 
	CAST(SUM((100.0-discount)*qty*s.price) * 100.0 / SUM(SUM((100.0-discount)*qty*s.price)) OVER() AS DECIMAL(4,2)) AS Percentage
FROM balanced_tree.sales s
JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
GROUP BY category_name

-- C9. What is the total transaction “penetration” for each product? 
--(hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

SELECT product_name, 
	CAST(COUNT(*)*100.0/(SELECT COUNT(DISTINCT txn_id) FROM balanced_tree.sales) AS DECIMAL(4,2)) AS Percentage
FROM balanced_tree.sales s
LEFT JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
GROUP BY product_name
ORDER BY Percentage DESC;


-- C10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

WITH cte1 AS(
	SELECT product_name, txn_id
	FROM balanced_tree.sales s
	JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
)

SELECT TOP 1
	t1.product_name, t2.product_name, t3.product_name, COUNT(*) AS count
FROM cte1 t1
JOIN cte1 t2 ON t1.txn_id = t2.txn_id AND t1.product_name < t2.product_name
JOIN cte1 t3 ON t2.txn_id = t3.txn_id AND t2.product_name < t3.product_name
GROUP BY t1.product_name, t2.product_name, t3.product_name
ORDER BY count DESC


--Reporting Challenge
--Write a single SQL script that combines all of the previous questions into a scheduled report that the Balanced Tree team can run at the beginning of each month to calculate the previous month’s values.

--Imagine that the Chief Financial Officer (which is also Danny) has asked for all of these questions at the end of every month.

--He first wants you to generate the data for January only - but then he also wants you to demonstrate that you can easily run the samne analysis for February without many changes (if at all).

--Feel free to split up your final outputs into as many tables as you need - but be sure to explicitly reference which table outputs relate to which question for full marks :)

DROP PROCEDURE IF EXISTS balanced_tree.ReportingMonthly;
GO

CREATE PROCEDURE balanced_tree.ReportingMonthly @month INT
AS
	--1
	SELECT TOP 3
	product_name, SUM(qty*s.price) AS revenue
	FROM balanced_tree.sales s
	JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
	WHERE DATEPART(MONTH, start_txn_time) = @month
	GROUP BY product_name
	ORDER BY revenue DESC;
	
	--2
	SELECT 
	segment_name, SUM(qty) AS quantity, SUM(qty*s.price) AS revenue, SUM(discount*qty*s.price/100.0) AS discount
	FROM 
		balanced_tree.sales s
	LEFT JOIN 
		balanced_tree.product_details p 
	ON 
		s.prod_id = p.product_id
	WHERE DATEPART(MONTH, start_txn_time) = @month
	GROUP BY 
		segment_name
	ORDER BY segment_name;

	--3
	WITH cte1 AS(
		SELECT 
			segment_name, product_name, SUM(qty) AS quantity, SUM(qty*s.price) AS revenue, SUM(discount*qty*s.price/100.0) AS discount
		FROM 
			balanced_tree.sales s
		LEFT JOIN 
			balanced_tree.product_details p 
		ON 
			s.prod_id = p.product_id
		WHERE DATEPART(MONTH, start_txn_time) = @month
		GROUP BY 
			segment_name, product_name
	)
	SELECT *
	FROM (
		SELECT *,
			RANK() OVER(PARTITION BY segment_name ORDER BY quantity DESC) as rank
		FROM cte1
	) A
	WHERE A.rank = 1;

	--4
	SELECT 
		category_name, SUM(qty) AS quantity, SUM(qty*s.price) AS revenue, SUM(discount*qty*s.price/100.0) AS discount
	FROM 
		balanced_tree.sales s
	LEFT JOIN 
		balanced_tree.product_details p 
	ON 
		s.prod_id = p.product_id
	WHERE DATEPART(MONTH, start_txn_time) = @month
	GROUP BY 
		category_name
	ORDER BY category_name;

	--5
	WITH cte1 AS(
		SELECT 
			category_name, product_name, SUM(qty) AS quantity, SUM(qty*s.price) AS revenue, SUM(discount*qty*s.price/100.0) AS discount
		FROM 
			balanced_tree.sales s
		LEFT JOIN 
			balanced_tree.product_details p 
		ON 
			s.prod_id = p.product_id
		WHERE DATEPART(MONTH, start_txn_time) = @month
		GROUP BY 
			category_name, product_name
	)
	SELECT *
	FROM (
		SELECT *,
			RANK() OVER(PARTITION BY category_name ORDER BY quantity DESC) as rank
		FROM cte1
	) A
	WHERE A.rank = 1;

	--6
	WITH cte1 AS(
		SELECT 
			segment_name, product_name, SUM((100.0-discount)*qty*s.price) AS product_revenue
		FROM 
			balanced_tree.sales s
		LEFT JOIN 
			balanced_tree.product_details p 
		ON 
			s.prod_id = p.product_id
		WHERE DATEPART(MONTH, start_txn_time) = @month
		GROUP BY 
			segment_name, product_name
	),
	cte2 AS(
		SELECT *,
			SUM(product_revenue) OVER(PARTITION BY segment_name) as segment_revenue
		FROM cte1
	)
	SELECT segment_name, product_name, 
		CAST(product_revenue*100.0/segment_revenue AS DECIMAL(4,2)) AS product_percentage
	FROM cte2
	ORDER BY segment_name, product_percentage DESC;


	--7
	WITH cte1 AS(
		SELECT 
			segment_name, category_name, SUM((100.0-discount)*qty*s.price) AS category_revenue
		FROM 
			balanced_tree.sales s
		LEFT JOIN 
			balanced_tree.product_details p 
		ON 
			s.prod_id = p.product_id
		WHERE DATEPART(MONTH, start_txn_time) = @month
		GROUP BY 
			segment_name, category_name

	),
	cte2 AS(
		SELECT *,
			SUM(category_revenue) OVER(PARTITION BY category_name) as segment_revenue
		FROM cte1
	)
	SELECT segment_name, category_name, 
		CAST(category_revenue*100.0/segment_revenue AS DECIMAL(4,2)) AS category_percentage
	FROM cte2
	ORDER BY segment_name, category_percentage DESC;

	--8
	SELECT category_name, 
		CAST(SUM((100.0-discount)*qty*s.price) * 100.0 / SUM(SUM((100.0-discount)*qty*s.price)) OVER() AS DECIMAL(4,2)) AS Percentage
	FROM balanced_tree.sales s
	JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
	WHERE DATEPART(MONTH, start_txn_time) = @month
	GROUP BY category_name;

	--9
	SELECT product_name, 
		CAST(COUNT(*)*100.0/(SELECT COUNT(DISTINCT txn_id) FROM balanced_tree.sales) AS DECIMAL(4,2)) AS Percentage
	FROM balanced_tree.sales s
	LEFT JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
	WHERE DATEPART(MONTH, start_txn_time) = @month
	GROUP BY product_name
	ORDER BY Percentage DESC;


	--10
	WITH cte1 AS(
		SELECT product_name, txn_id
		FROM balanced_tree.sales s
		JOIN balanced_tree.product_details p ON s.prod_id = p.product_id
		WHERE DATEPART(MONTH, start_txn_time) = @month
	)

	SELECT TOP 1
		t1.product_name, t2.product_name, t3.product_name, COUNT(*) AS count
	FROM cte1 t1
	JOIN cte1 t2 ON t1.txn_id = t2.txn_id AND t1.product_name < t2.product_name
	JOIN cte1 t3 ON t2.txn_id = t3.txn_id AND t2.product_name < t3.product_name
	GROUP BY t1.product_name, t2.product_name, t3.product_name
	ORDER BY count DESC;
GO


EXEC balanced_tree.ReportingMonthly 3;


--																	Bonus Challenge
--Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

SELECT pp.product_id,
	pp.price,
	ph.level_text + ' - ' + CASE
		WHEN ph.parent_id = 1
		OR ph.parent_id = 3
		OR ph.parent_id = 4 THEN 'Womens'
		ELSE 'Mens'
	END AS product_name,
	CASE
		WHEN ph.parent_id = 1
		OR ph.parent_id = 3
		OR ph.parent_id = 4 THEN 1
		ELSE 2
	END AS category_id,
	ph.parent_id AS segment_id,
	pp.id AS style_id,
	CASE
		WHEN ph.parent_id = 1
		OR ph.parent_id = 3
		OR ph.parent_id = 4 THEN 'Womens'
		ELSE 'Mens'
	END AS category_name,
	CASE
		WHEN ph.parent_id = 3 THEN 'Jeans'
		WHEN ph.parent_id = 4 THEN 'Jacket'
		WHEN ph.parent_id = 5 THEN 'Shirt'
		WHEN ph.parent_id = 6 THEN 'Socks'
	END AS segment_name,
	ph.level_text AS style_name
FROM balanced_tree.product_hierarchy AS ph
	JOIN balanced_tree.product_prices AS pp ON ph.id = pp.id;