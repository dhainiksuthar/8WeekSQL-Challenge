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
  





-- What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) FROM sales JOIN menu ON sales.product_id = menu.product_id GROUP BY customer_id;
  
-- How many days has each customer visited the restaurant?
SELECT temp.customer_id, COUNT(*) FROM (
SELECT customer_id, order_date, count(*) FROM sales GROUP BY customer_id, order_date) as temp GROUP BY customer_id;
  
-- What was the first item from the menu purchased by each customer?
SELECT sales.customer_id,  min(order_date) FROM sales JOIN menu ON sales.product_id = menu.product_id GROUP BY customer_id
  
-- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT customer_id, count(*) FROM sales WHERE product_id IN(
SELECT product_id FROM (
SELECT product_id, COUNT(*) FROM sales GROUP BY product_id order by count desc) as temp FETCH FIRST ROW ONLY) GROUP BY customer_id;

-- Which item was the most popular for each customer?
SELECT customer_id, product_id, count(*) FROM sales GROUP BY customer_id, product_id;
  

