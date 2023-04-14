
									--A. Customer Nodes Exploration


-- A1. How many unique nodes are there on the Data Bank system?

SELECT COUNT(DISTINCT NODE_ID) FROM CUSTOMER_NODES


-- A2. What is the number of nodes per region?
SELECT R.REGION_NAME, COUNT(DISTINCT C.NODE_ID)  FROM CUSTOMER_NODES C
JOIN REGIONS R ON C.REGION_ID = R.REGION_ID
GROUP BY R.REGION_NAME;


-- A3. How many customers are allocated to each region?

SELECT r.region_name, COUNT(DISTINCT customer_id) FROM customer_nodes c
JOIN regions r ON c.region_id = r.region_id
GROUP BY r.region_name


-- A4. How many days on average are customers reallocated to a different node?

SELECT * FROM customer_nodes order by customer_id, start_date

WITH cte1 AS(
	SELECT customer_id, node_id, start_date, end_date, DATEDIFF(DAY, start_date, end_date) AS diff
	FROM customer_nodes
	WHERE end_date <> '9999-12-31'
	GROUP BY customer_id, node_id, start_date, end_date
	),

cte2 AS(
	SELECT customer_id, node_id, SUM(diff) AS diffsum
	FROM cte1
	GROUP BY customer_id, node_id
)

SELECT AVG(diffsum)
FROM cte2;

-- A5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH cte AS(
	SELECT 
		customer_id, region_id, node_id, DATEDIFF(DAY, start_date, end_date) AS duration
	FROM customer_nodes
	WHERE end_date != '9999-12-31'
)
SELECT DISTINCT region_id,
	percentile_cont(0.5) WITHIN GROUP(ORDER BY duration) OVER(PARTITION BY region_id) AS "PERCENTILE_COUNT_80"
FROM cte



									--B. Customer Transactions

--What is the unique count and total amount for each transaction type?

SELECT 
	txn_type, COUNT(*) AS count, SUM(txn_amount) AS total_amount 
FROM customer_transactions
GROUP BY txn_type;

--What is the average total historical deposit counts and amounts for all customers?

SELECT customer_id, COUNT(*) AS count, SUM(txn_amount) AS total_amount FROM customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id
ORDER BY customer_id

SELECT * FROM customer_transactions

--For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

WITH CTE AS(
	SELECT customer_id, DATEPART(MONTH, txn_date) AS month,
		SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
		SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
		SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
    FROM customer_transactions
	GROUP BY customer_id, DATEPART(MONTH, txn_date)
)
SELECT month, COUNT(customer_id) AS count FROM CTE
WHERE deposit_count > 1 AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY month

--What is the closing balance for each customer at the end of the month?

SELECT * FROM customer_transactions
ORDER BY customer_id;

WITH cte1 AS(
	SELECT customer_id, DATEPART(MONTH, txn_date) AS month,
		SUM( CASE WHEN txn_type = 'deposit' THEN txn_amount
				ELSE 0 - txn_amount END) AS amount
	FROM customer_transactions
	GROUP BY customer_id, DATEPART(MONTH, txn_date)
),

cte2 AS(
	SELECT customer_id, month, amount, amount + COALESCE(LAG(amount) OVER(PARTITION BY customer_id ORDER BY month), 0) AS closing_amount, 
	COALESCE(LEAD(month) OVER(PARTITION BY customer_id ORDER BY month), 5) AS next_month
	FROM cte1
),

cte3 AS(
	SELECT customer_id, month, closing_amount, next_month
	FROM cte2
	UNION ALL
	SELECT customer_id, month+1, closing_amount, next_month
	FROM cte3
	WHERE month < next_month-1
)

SELECT customer_id, month, closing_amount FROM cte3
ORDER BY customer_id, month


--What is the percentage of customers who increase their closing balance by more than 5%?

WITH cte1 AS(
	SELECT customer_id, DATEPART(MONTH, txn_date) AS month,
		SUM( CASE WHEN txn_type = 'deposit' THEN txn_amount
				ELSE 0 - txn_amount END) AS amount
	FROM customer_transactions
	GROUP BY customer_id, DATEPART(MONTH, txn_date)
),
cte2 AS(
	SELECT customer_id, month, amount + COALESCE(LAG(amount) OVER(PARTITION BY customer_id ORDER BY month), 0) AS closing_amount, 
	COALESCE(LEAD(month) OVER(PARTITION BY customer_id ORDER BY month), 5) AS next_month
	FROM cte1
),
cte3 AS(
	SELECT customer_id, month, closing_amount, next_month
	FROM cte2
	UNION ALL
	SELECT customer_id, month+1, closing_amount, next_month
	FROM cte3
	WHERE month < next_month-1
),
cte4 AS(
	SELECT *, LAG(closing_amount) OVER(PARTITION BY customer_id ORDER BY month) AS prev_closing_amount
	FROM cte3
),
cte5 AS(
	SELECT * FROM cte4	
	WHERE prev_closing_amount IS NULL OR
		prev_closing_amount * 1.05 < closing_amount
)

SELECT 
	CAST(COUNT(customer_id)*100.0/(SELECT COUNT(DISTINCT customer_id) FROM customer_nodes) AS DECIMAL(4, 2)) AS Percentage
FROM (
	SELECT customer_id, COUNT(*) as count
	FROM cte5 
	GROUP BY customer_id 
	HAVING COUNT(*) = 4
) t1;




										--C. Data Allocation Challenge
--To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

--Option 1: data is allocated based off the amount of money at the end of the previous month
--Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
--Option 3: data is updated real-time
--For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

--running customer balance column that includes the impact each transaction
--customer balance at the end of each month
--minimum, average and maximum values of the running balance for each customer
--Using all of the data available - how much data would have been required for each option on a monthly basis?

--running customer balance column that includes the impact each transaction
WITH cte1 AS(
SELECT 
	*, SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE 0-txn_amount END) OVER(PARTITION BY customer_id ORDER BY txn_date) AS running_balance	
FROM customer_transactions
)

SELECT * INTO #running_balance FROM cte1
SELECT * FROM #running_balance;
--customer balance at the end of each month

WITH cte1 AS(
	SELECT customer_id, DATEPART(MONTH, txn_date) AS month,
		SUM( CASE WHEN txn_type = 'deposit' THEN txn_amount
				ELSE 0 - txn_amount END) AS amount
	FROM customer_transactions
	GROUP BY customer_id, DATEPART(MONTH, txn_date)
),

cte2 AS(
	SELECT customer_id, month, amount, amount + COALESCE(LAG(amount) OVER(PARTITION BY customer_id ORDER BY month), 0) AS closing_amount, 
	COALESCE(LEAD(month) OVER(PARTITION BY customer_id ORDER BY month), 5) AS next_month
	FROM cte1
),

cte3 AS(
	SELECT customer_id, month, closing_amount, next_month
	FROM cte2
	UNION ALL
	SELECT customer_id, month+1, closing_amount, next_month
	FROM cte3
	WHERE month < next_month-1
)

SELECT customer_id, month, closing_amount FROM cte3
ORDER BY customer_id, month

--minimum, average and maximum values of the running balance for each customer

SELECT 
	customer_id, MIN(running_balance) OVER(PARTITION BY customer_id) AS minimum,
	MAX(running_balance) OVER(PARTITION BY customer_id) AS maximum,
	AVG(running_balance) OVER(PARTITION BY customer_id) AS average
FROM #running_balance;



--D. Extra Challenge
--Data Bank wants to try another option which is a bit more difficult to implement - they want to calculate data growth using an interest calculation, just 
--like in a traditional savings account you might have with a bank.

--If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers by increasing their data allocation based off the interest 
--calculated on a daily basis at the end of each day, how much data would be required for this option on a monthly basis?

--Special notes:

--Data Bank wants an initial calculation which does not allow for compounding interest, however they may also be interested in a daily compounding 
--interest calculation so you can try to perform this calculation if you have the stamina!

WITH cte1 AS(
	SELECT
		customer_id, txn_date, running_balance, LEAD(txn_date) OVER(PARTITION BY customer_id ORDER BY txn_date) AS next_txn_date
	FROM
		#running_balance),
cte2 AS(
SELECT
	customer_id, DATEPART(MONTH, txn_date) AS month, running_balance*(0.06/365)*DATEDIFF(DAY, txn_date, COALESCE(next_txn_date, '2020-04-30')) AS Interest
FROM cte1)

SELECT 
	month, SUM(interest)
FROM cte2
GROUP BY month
ORDER BY month;