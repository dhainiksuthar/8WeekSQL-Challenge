-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) FROM sales JOIN menu ON sales.product_id = menu.product_id GROUP BY customer_id;
  
-- 2. How many days has each customer visited the restaurant?
SELECT temp.customer_id, COUNT(*) FROM (
SELECT customer_id, order_date, count(*) FROM sales GROUP BY customer_id, order_date) as temp GROUP BY customer_id;
  
-- 3. What was the first item from the menu purchased by each customer?
SELECT 
	customer_id, order_date, product_id, product_name
FROM
	(
		SELECT 
			sales.customer_id, order_date, sales.product_id, product_name,
			ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) as rank
		FROM 
			sales 
		JOIN menu ON sales.product_id = menu.product_id 
	) a
WHERE
	rank = 1;

  
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	customer_id, count(*), MAX(product_id) AS product_id 
FROM 
	sales 
WHERE 
	product_id IN(
				SELECT product_id 
				FROM (
					SELECT 
						product_id, COUNT(*) 
					FROM sales 
					GROUP BY 
						product_id 
					order by 
						count desc
				) 
				AS temp FETCH FIRST ROW ONLY
		) 
GROUP BY 
	customer_id;


-- 5. Which item was the most popular for each customer?
SELECT customer_id, product_id, count FROM(
			SELECT 
					customer_id, product_id, count(*), 
					RANK() OVER(PARTITION BY customer_id ORDER BY count(*) DESC) 
			FROM 
				sales 
			GROUP BY 
				customer_id, product_id 
			ORDER BY customer_id) AS a
WHERE 
	rank = 1;
  
-- 6. Which item was purchased first by the customer after they became a member?
SELECT 
	customer_id, product_id, product_name, order_date 
FROM(
	SELECT 
		sales.customer_id, product_id, order_date, 
		RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date)
	FROM 
		sales
	JOIN
		members ON sales.customer_id = members.customer_id
	WHERE 
		members.join_date <= sales.order_date) as a 
JOIN 
	menu USING(product_id)
WHERE 
	rank = 1;

-- 7. Which item was purchased just before the customer became a member?
SELECT 
	customer_id, product_id, product_name, order_date 
FROM
	(
		SELECT 
			sales.customer_id, product_id, order_date, 
			RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date DESC)
		FROM 
			sales
		JOIN
			members ON sales.customer_id = members.customer_id
		WHERE 
			members.join_date > sales.order_date
	) AS a 
JOIN 
	menu USING(product_id)
WHERE 
	rank = 1;


-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 
	sales.customer_id, COUNT(*) AS numOfItems, SUM(price) AS totalAmount
FROM 
	sales
JOIN
	members ON sales.customer_id = members.customer_id
JOIN
	menu USING(product_id)
WHERE 
	members.join_date > sales.order_date
GROUP BY 
	sales.customer_id


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id,
		SUM(
			CASE WHEN product_name = 'sushi' THEN price*20
			ELSE price*10
			END
		) AS Points
FROM sales
JOIN menu
USING(product_id)
GROUP BY sales.customer_id


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT customer_id,
		SUM(
			CASE WHEN product_name = 'sushi' OR order_date BETWEEN join_date AND join_date + INTERVAL '6 DAY' THEN price*20
			ELSE price*10
			END
		) AS Points
FROM sales
JOIN members USING(customer_id)
JOIN menu
USING(product_id)
WHERE EXTRACT(MONTH FROM order_date) = 1
GROUP BY sales.customer_id


-- Bonus Questions
-- Create table with following columns
-- customer_id	order_date	product_name	price	member
SELECT 
		sales.customer_id, sales.order_date, menu.product_name, menu.price,
		CASE WHEN order_date >= join_date THEN 'Y' ELSE 'N' END AS Member
FROM 
	sales
FULL OUTER JOIN 
	members USING(customer_id)
JOIN 
	menu USING(product_id)


-- Rank All The Things

WITH ct1 AS
		(
			SELECT 
					sales.customer_id, sales.order_date, menu.product_name, menu.price,
					CASE WHEN order_date >= join_date THEN 'Y' ELSE 'N' END AS Member
			FROM 
				sales
			FULL OUTER JOIN 
				members USING(customer_id)
			JOIN 
				menu USING(product_id)
		)

SELECT *,
		CASE
			WHEN member = 'N' THEN NULL
			ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
		END AS rank
FROM
	ct1;


