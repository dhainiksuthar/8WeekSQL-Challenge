												-- A Data Cleansing Steps
--In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

--Convert the week_date to a DATE format

--Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc

--Add a month_number with the calendar month for each week_date value as the 3rd column

--Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values

--Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

--segment	age_band
--1	Young Adults
--2	Middle Aged
--3 or 4	Retirees
--Add a new demographic column using the following mapping for the first letter in the segment values:
--segment	demographic
--C	Couples
--F	Families
--Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns

--Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

DROP TABLE IF EXISTS data_mart.weekly_sales_cleaned;

WITH cte1 AS(
	SELECT region, platform, segment, customer_type, transactions, sales,
		CONVERT(DATE, week_date, 3) AS week_date
	FROM data_mart.weekly_sales
)
SELECT 
	week_date,
	DATEPART(WEEk, week_date) AS week_number,
	DATEPART(MONTH, week_date) AS month_number,
	DATEPART(YEAR, week_date) AS calendar_year,
	region, platform, 
	
	CASE WHEN segment IN ('F1', 'C1') THEN 'Young Adults'
		 WHEN segment IN ('F2', 'C2') THEN 'Middle Aged'
		 WHEN segment IN ('C3', 'F3', 'C4') THEN 'Retirees'
		 ELSE 'unknown'
	END AS age_band,

	CASE WHEN segment LIKE 'C%' THEN 'Couples'
		 WHEN segment LIKE 'F%' THEN 'Families'
		 ELSE 'unknown'
	END AS demographic
	, customer_type, transactions, 
	CAST(sales AS BIGINT) sales, 
	CAST((sales*1.0)/transactions AS DECIMAL(10,2)) AS avg_transaction
INTO 
	data_mart.weekly_sales_cleaned
FROM 
	cte1;



--									2. Data Exploration

--What day of the week is used for each week_date value?

SELECT DISTINCT
	DATENAME(WEEKDAY, week_date) AS dayofweek
FROM data_mart.weekly_sales_cleaned;

--What range of week numbers are missing from the dataset?
-- 1 - 12 and 37 - 53

SELECT 
	* 
FROM GENERATE_SERIES(1, 53) 
WHERE value NOT IN (
	SELECT 
		DISTINCT week_number 
	FROM data_mart.weekly_sales_cleaned)

--How many total transactions were there for each year in the dataset?

SELECT 
	DATEPART(YEAR, week_date) AS Year, SUM(transactions) AS total_transaction 
FROM data_mart.weekly_sales_cleaned 
GROUP BY DATEPART(YEAR, week_date)


--What is the total sales for each region for each month?

SELECT region, DATEPART(MONTH, week_date) AS month, SUM(sales) AS total_sales
FROM data_mart.weekly_sales_cleaned
GROUP BY region, DATEPART(MONTH, week_date)
ORDER BY region, month;

--What is the total count of transactions for each platform

SELECT platform, SUM(transactions) AS number_of_transactions
FROM data_mart.weekly_sales_cleaned
GROUP BY platform
ORDER BY platform

--What is the percentage of sales for Retail vs Shopify for each month?
WITH cte1 AS(
SELECT 
	calendar_year, month_number,
	SUM(CASE
		WHEN platform = 'Shopify' THEN sales
		ELSE 0
	END) AS shopify_sum,

	SUM(CASE
		WHEN platform = 'Retail' THEN sales
		ELSE 0
	END) AS retail_sum,

	SUM(sales) AS total_sales
FROM
	data_mart.weekly_sales_cleaned
GROUP BY calendar_year, month_number)

SELECT 
	calendar_year, month_number, 
	CAST(shopify_sum*100.0/total_sales AS DECIMAL(4, 2)) AS shopify_percentage, 
	CAST(retail_sum*100.0/total_sales AS DECIMAL(4, 2)) AS retail_percentage
FROM
	cte1

--What is the percentage of sales by demographic for each year in the dataset?

WITH cte1 AS(
SELECT 
	calendar_year,
	SUM(CASE
		WHEN demographic = 'Families' THEN sales
		ELSE 0
	END) AS family_sum,

	SUM(CASE
		WHEN demographic = 'Couples' THEN sales
		ELSE 0
	END) AS couple_sum,

	SUM(CASE
		WHEN demographic = 'unknown' THEN sales
		ELSE 0
	END) AS unknown_sum,

	SUM(sales) AS total_sales
FROM
	data_mart.weekly_sales_cleaned
GROUP BY calendar_year)

SELECT 
	calendar_year, 
	CAST(family_sum*100.0/total_sales AS DECIMAL(4, 2)) AS family_percentage, 
	CAST(couple_sum*100.0/total_sales AS DECIMAL(4, 2)) AS couple_percentage,
	CAST(unknown_sum*100.0/total_sales AS DECIMAL(4, 2)) AS unknown_percentage
FROM
	cte1
ORDER BY calendar_year;


--Which age_band and demographic values contribute the most to Retail sales?

SELECT 
	age_band, demographic, platform, SUM(sales) as total_retail_sales
FROM data_mart.weekly_sales_cleaned
WHERE platform = 'Retail'
GROUP BY age_band, demographic, platform
ORDER BY total_retail_sales DESC

--Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

SELECT calendar_year, platform,
	CAST(AVG(avg_transaction) AS DECIMAL(3, 0)) AS as_per_avg_transaction_column,
	SUM(sales)/SUM(transactions) AS sales_and_transaction
FROM 
	data_mart.weekly_sales_cleaned 
GROUP BY 
	calendar_year, platform
ORDER BY calendar_year


												--3. Before & After Analysis

--This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

--Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

--We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

--Using this analysis approach - answer the following questions:

--What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

DECLARE @week INT;
DECLARE @year INT;
SELECT @week = week_number, @year = calendar_year FROM data_mart.weekly_sales_cleaned WHERE week_date = '2020-06-15';

WITH cte1 AS(SELECT 
	SUM(CASE
		WHEN week_number BETWEEN @week-4 AND @week-1 THEN sales
		END) AS before_change,
	SUM(CASE
		WHEN week_number BETWEEN @week AND @week+3 THEN sales
		END) AS after_change
FROM data_mart.weekly_sales_cleaned      
WHERE calendar_year = @year)

SELECT before_change, after_change,   after_change - before_change AS variance, 
	ROUND(100 * (after_change - before_change) / before_change,2) AS percentage
FROM cte1; 

--What about the entire 12 weeks before and after?

DECLARE @week INT;
DECLARE @year INT;
SELECT @week = week_number, @year = calendar_year FROM data_mart.weekly_sales_cleaned WHERE week_date = '2020-06-15';

WITH cte1 AS(SELECT 
	SUM(CASE
		WHEN week_number BETWEEN @week-12 AND @week-1 THEN sales
		END) AS before_change,
	SUM(CASE
		WHEN week_number BETWEEN @week AND @week+11 THEN sales
		END) AS after_change
FROM data_mart.weekly_sales_cleaned      
WHERE calendar_year = @year)

SELECT before_change, after_change,   after_change - before_change AS variance, 
	ROUND(100 * (after_change - before_change) / before_change,2) AS percentage
FROM cte1;


--How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?




SELECT * FROM data_mart.weekly_sales_cleaned