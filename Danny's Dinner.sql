CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  





-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) FROM sales JOIN menu ON sales.product_id = menu.product_id GROUP BY customer_id;
  
-- 2. How many days has each customer visited the restaurant?
SELECT temp.customer_id, COUNT(*) FROM (
SELECT customer_id, order_date, count(*) FROM sales GROUP BY customer_id, order_date) as temp GROUP BY customer_id;
  
-- 3. What was the first item from the menu purchased by each customer?
SELECT sales.customer_id,  min(order_date) FROM sales JOIN menu ON sales.product_id = menu.product_id GROUP BY customer_id
  
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT customer_id, count(*) FROM sales WHERE product_id IN(
SELECT product_id FROM (
SELECT product_id, COUNT(*) FROM sales GROUP BY product_id order by count desc) as temp FETCH FIRST ROW ONLY) GROUP BY customer_id;

-- 5. Which item was the most popular for each customer?
SELECT customer_id, product_id, count FROM(
SELECT customer_id, product_id, count(*), RANK() OVER(PARTITION BY customer_id ORDER BY count(*) DESC) FROM sales GROUP BY customer_id, product_id ORDER BY customer_id) as a
WHERE rank = 1;
  
-- 6. Which item was purchased first by the customer after they became a member?
SELECT customer_id, product_id, product_name, order_date FROM(
SELECT sales.customer_id, product_id, order_date, RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date)
FROM 
	sales
JOIN
	members
ON sales.customer_id = members.customer_id
WHERE members.join_date <= sales.order_date) as a 
JOIN menu USING(product_id)
WHERE rank = 1
;

-- Which item was purchased just before the customer became a member?
SELECT customer_id, product_id, product_name, order_date FROM(
SELECT sales.customer_id, product_id, order_date, RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date DESC)
FROM 
	sales
JOIN
	members
ON sales.customer_id = members.customer_id
WHERE members.join_date > sales.order_date) as a 
JOIN menu USING(product_id)
WHERE rank = 1;


-- What is the total items and amount spent for each member before they became a member?
SELECT sales.customer_id, COUNT(*) AS numOfItems, SUM(price) AS totalAmount
FROM 
	sales
JOIN
	members
ON sales.customer_id = members.customer_id
JOIN
	menu
USING(product_id)
WHERE members.join_date > sales.order_date
GROUP BY sales.customer_id


-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

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
-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
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
GROUP BY sales.customer_id

-- Bonus Questions
-- Create table with following columns
-- customer_id	order_date	product_name	price	member
SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
		CASE WHEN order_date >= join_date THEN 'Y' ELSE 'N' END AS Member
FROM sales
FULL OUTER JOIN members USING(customer_id)
JOIN menu
USING(product_id)


SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
		CASE WHEN order_date < join_date THEN NULL ELSE RANK() OVER(PARTITION BY customer_id ORDER BY order_date) END AS rnk,
		CASE WHEN order_date >= join_date THEN 'Y' ELSE 'N' END AS Member
FROM sales
FULL OUTER JOIN members USING(customer_id)
JOIN menu
USING(product_id)
WHERE 


