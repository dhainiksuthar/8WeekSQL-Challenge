														-- A Data Exploration and Cleansing

-- A1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

ALTER TABLE fresh_segments.interest_metrics 
ALTER COLUMN month_year VARCHAR(30);

UPDATE fresh_segments.interest_metrics 
SET month_year = DATEFROMPARTS(_year, _month, '01');


-- A2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the 
--null values appearing first?

SELECT * FROM 
fresh_segments.interest_metrics
ORDER BY month_year


-- A3. What do you think we should do with these null values in the fresh_segments.interest_metrics

DELETE
FROM fresh_segments.interest_metrics
WHERE month_year IS NULL;

-- A4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? 
--What about the other way around?

SELECT COUNT(*) AS [ids not in map]
FROM fresh_segments.interest_metrics 
WHERE interest_id NOT IN (
	SELECT id
	FROM fresh_segments.interest_map
);

SELECT COUNT(*) [ids not in matrics]
FROM fresh_segments.interest_map 
WHERE id NOT IN (
	SELECT interest_id
	FROM fresh_segments.interest_metrics
);


-- A5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table

SELECT COUNT(*)
FROM fresh_segments.interest_map


-- A6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your 
--joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.

SELECT * FROM 
fresh_segments.interest_metrics matrics
JOIN fresh_segments.interest_map map
ON matrics.interest_id = map.id
WHERE matrics.interest_id = 21246


-- A7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? 
--Do you think these values are valid and why?

SELECT COUNT(*) FROM 
fresh_segments.interest_metrics matrics
JOIN fresh_segments.interest_map map
ON matrics.interest_id = map.id
WHERE month_year < created_at


										-- B. Interest Analysis


-- B1. Which interests have been present in all month_year dates in our dataset?

SELECT _year, _month, COUNT(*) 
FROM fresh_segments.interest_metrics 
GROUP BY _year, _month
ORDER BY CAST(_year AS INT), CAST(_month AS INT)

SELECT *
FROM fresh_segments.interest_metrics
ORDER BY interest_id, CAST(_year AS INT), CAST(_month AS INT)

WITH cte AS(
	SELECT interest_id, COUNT(DISTINCT month_year) AS total_month
	FROM fresh_segments.interest_metrics
	GROUP BY interest_id
)

SELECT COUNT(interest_id)
FROM cte
WHERE total_month = 14;

-- B2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - 
--which total_months value passes the 90% cumulative percentage value?

WITH cte1 AS(
	SELECT interest_id, COUNT(DISTINCT month_year) AS total_month
	FROM fresh_segments.interest_metrics
	WHERE interest_id IS NOT NULL
	GROUP BY interest_id
),
cte2 AS(
	SELECT total_month, COUNT(*) AS interest_count
	FROM cte1
	GROUP BY total_month
)
SELECT 
	total_month, interest_count, 
	CAST(100.0*SUM(interest_count) OVER(ORDER BY total_month DESC)/SUM(interest_count) OVER() AS NUMERIC(5,2)) AS cumulative_percentage
FROM cte2;


-- B3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - 
--how many total data points would we be removing?

WITH cte AS(
	SELECT interest_id, COUNT(DISTINCT month_year) as count
	FROM fresh_segments.interest_metrics
	GROUP BY interest_id
	HAVING COUNT(DISTINCT month_year) < 6
)
SELECT COUNT(*) FROM cte
LEFT JOIN fresh_segments.interest_metrics im
ON cte.interest_id = im.interest_id


-- B4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present 
--to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.

-- B5. After removing these interests - how many unique interests are there for each month?

WITH cte AS(
	SELECT interest_id, COUNT(DISTINCT month_year) as count
	FROM fresh_segments.interest_metrics
	GROUP BY interest_id
	HAVING COUNT(DISTINCT month_year) >= 6
)

SELECT month_year, COUNT(interest_id) AS interest_count
FROM fresh_segments.interest_metrics
WHERE interest_id IN (SELECT interest_id FROM cte)
GROUP BY month_year
ORDER BY month_year


												-- C. Segment Analysis
DROP TABLE IF EXISTS #filtered_data;
WITH cte AS(
	SELECT interest_id, COUNT(DISTINCT month_year) as count
	FROM fresh_segments.interest_metrics
	GROUP BY interest_id
	HAVING COUNT(DISTINCT month_year) >= 6
)

SELECT *
	INTO #filtered_data
FROM fresh_segments.interest_metrics
WHERE interest_id IN (SELECT interest_id FROM cte)

SELECT * FROM #filtered_data
-- C1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests 
--which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the 
--corresponding month_year

SELECT TOP 10 month_year, fd.interest_id, interest_name, fd.composition
FROM #filtered_data fd
JOIN fresh_segments.interest_map map
ON fd.interest_id = map.id
ORDER BY composition DESC

SELECT TOP 10 month_year, fd.interest_id, interest_name, fd.composition
FROM #filtered_data fd
JOIN fresh_segments.interest_map map
ON fd.interest_id = map.id
ORDER BY composition

-- C2. Which 5 interests had the lowest average ranking value?

SELECT TOP 5
	interest_name, AVG(ranking) AS avg_ranking
FROM #filtered_data fd
JOIN fresh_segments.interest_map im
ON fd.interest_id = im.id
GROUP BY interest_name
ORDER BY avg_ranking DESC 

-- C3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
DROP TABLE IF EXISTS #top_interest;
SELECT TOP 5
	 interest_name, CAST(STDEV(percentile_ranking) AS DECIMAL(6, 2)) AS stdev
	 INTO #top_interest
FROM #filtered_data fd
JOIN fresh_segments.interest_map im
ON fd.interest_id = im.id
GROUP BY interest_name
ORDER BY stdev DESC

SELECT * FROM #top_interest;

-- C4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and 
--its corresponding year_month value? Can you describe what is happening for these 5 interests?

WITH cte AS(
SELECT 
	ti.interest_name, percentile_ranking, month_year, 
	RANK() OVER(PARTITION BY ti.interest_name ORDER BY percentile_ranking) formin,
	RANK() OVER(PARTITION BY ti.interest_name ORDER BY percentile_ranking DESC) formax
FROM #filtered_data fd
JOIN fresh_segments.interest_map im
ON fd.interest_id = im.id
JOIN #top_interest ti
ON ti.interest_name = im.interest_name
)

SELECT month_year, interest_name, percentile_ranking
FROM cte
WHERE formin = 1 OR formax = 1;


-- C5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services 
--should we show to these customers and what should we avoid?



											-- D. Index Analysis
--The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.

--Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.

-- D1. What is the top 10 interests by the average composition for each month?

DROP TABLE IF EXISTS #top_interest_per_month;
WITH cte1 AS(
	SELECT 
		month_year, interest_name,
		composition*1.0/index_value avgcomposition,
		RANK() OVER(PARTITION BY month_year ORDER BY composition*1.0/index_value DESC) as rnk
	FROM
		#filtered_data metrics
	JOIN fresh_segments.interest_map map
	ON metrics.interest_id = map.id
)
SELECT *
INTO #top_interest_per_month
FROM cte1
WHERE rnk <= 10
ORDER BY month_year;
SELECT * FROM #top_interest_per_month;


-- D2. For all of these top 10 interests - which interest appears the most often?

SELECT 
	interest_name, COUNT(*) AS count
FROM #top_interest_per_month
GROUP BY interest_name
ORDER BY count DESC;


-- D3. What is the average of the average composition for the top 10 interests for each month?

SELECT month_year, CAST(AVG(avgcomposition) AS NUMERIC(4,2)) AS avgcompostion_per_month
FROM #top_interest_per_month
GROUP BY month_year;


-- D4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the 
--previous top ranking interests in the same output shown below.

WITH cte AS (	
	SELECT month_year, interest_name, 
		avgcomposition [max_index_composition],
		CAST(AVG(avgcomposition) OVER(ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS decimal(10,2)) [3_month_moving_avg],
		CONCAT(LAG(interest_name) OVER (ORDER BY month_year), ': ', LAG(avgcomposition) OVER (ORDER BY month_year)) [1_month_ago],
		CONCAT(LAG(interest_name, 2) OVER (ORDER BY month_year) , ': ', LAG(avgcomposition, 2) OVER (ORDER BY month_year)) [2_month_ago]
	FROM #top_interest_per_month 
	WHERE rnk = 1
	)
SELECT * 
FROM cte
WHERE month_year BETWEEN '2018-09-01' AND '2019-08-01'
ORDER BY month_year;

-- D5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is 
--not quite right with the overall business model for Fresh Segments?

/*
I think it's because of seasonal. People make plans for trips when summer is coming which is time of holiday.
Other than that time work is first priority. So this is because of change in season.
Another possible reason can be that interests' may have changed time to time. 
So, because of this reason composition might change from month to month.
*/
