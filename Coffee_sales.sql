select count(*) from coffee_sales;
DESCRIBE coffee_sales;

-- date is in text format and needs to be convered to date
update coffee_sales
Set transaction_date=str_to_date(transaction_date, "%m/%d/%Y");

SET sql_safe_updates=0;

alter table coffee_sales
modify column transaction_date date;

select * from coffee_sales;

-- time is in text format and needs to be converted to time

update coffee_sales
Set transaction_time=str_to_date(transaction_time, "%H-%i-%Y");

alter table coffee_sales
modify column transaction_time time;

-- column name has junk character which has to be corrected
ALTER TABLE coffee_sales
CHANGE COLUMN ï»¿transaction_id transaction_id INT;

-- Find the total sales for the month of march
SELECT ROUND(SUM(unit_price * transaction_qty)) as Total_Sales 
FROM coffee_sales 
WHERE MONTH(transaction_date) = 3; -- for month of (CM-May)

-- Month on month difference / Month on month growth 
SELECT 
    MONTH(transaction_date) AS month, -- Month number
    ROUND(SUM(unit_price * transaction_qty)) AS total_sales, -- total sales for that specific month
    (SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty), 1) -- difference between current and previous month sales
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(unit_price * transaction_qty), 1)  -- previous month sales 
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage -- calculating the percentage
FROM 
    coffee_sales
WHERE 
    MONTH(transaction_date) IN (4, 5) -- for months of April and May
GROUP BY 
    1
ORDER BY 
    1;
    
-- calculate the total order
SELECT COUNT(transaction_id) as Total_Orders
FROM coffee_sales 
WHERE MONTH (transaction_date)= 5; -- for month of (CM-May)

-- calculating the month on month number of orders difference and number of orders growth

SELECT 
    MONTH(transaction_date) AS month,
    ROUND(COUNT(transaction_id)) AS total_orders,
    (COUNT(transaction_id) - LAG(COUNT(transaction_id), 1) 
    OVER (ORDER BY MONTH(transaction_date))) / LAG(COUNT(transaction_id), 1) 
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM 
    coffee_sales
WHERE 
    MONTH(transaction_date) IN (4, 5) -- for April and May
GROUP BY 
    1
ORDER BY 
    1;

-- total quantity
SELECT SUM(transaction_qty) as Total_Quantity_Sold
FROM coffee_sales 
WHERE MONTH(transaction_date) = 5; -- for month of (CM-May)

-- total quantity - Month no month difference and growth
SELECT 
    MONTH(transaction_date) AS month,
    ROUND(SUM(transaction_qty)) AS total_quantity_sold,
    (SUM(transaction_qty) - LAG(SUM(transaction_qty), 1) 
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(transaction_qty), 1) 
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM 
    coffee_sales
WHERE 
    MONTH(transaction_date) IN (4, 5)   -- for April and May
GROUP BY 
    1
ORDER BY 
    1;

-- calculating daily sales, quantity and orders for a particular day

SELECT
    SUM(unit_price * transaction_qty) AS total_sales,
    SUM(transaction_qty) AS total_quantity_sold,
    COUNT(transaction_id) AS total_orders
FROM 
    coffee_sales
WHERE 
    transaction_date = '2023-03-11'; 
    
SELECT 
    CONCAT(ROUND(SUM(unit_price * transaction_qty) / 1000, 1),'K') AS total_sales,
    CONCAT(ROUND(COUNT(transaction_id) / 1000, 1),'K') AS total_orders,
    CONCAT(ROUND(SUM(transaction_qty) / 1000, 1),'K') AS total_quantity_sold
FROM 
    coffee_sales
WHERE 
    transaction_date = '2023-03-11'; 

SELECT AVG(total_sales) AS average_sales
FROM (
    SELECT 
        SUM(unit_price * transaction_qty) AS total_sales
    FROM 
        coffee_sales
	WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        transaction_date
) AS internal_query;

-- calculating weekend and weekday sales 
select 
case when dayofweek(transaction_date) in (1,7) then "weekends"
else "weekdays" 
end as date_type,
SUM(unit_price * transaction_qty) AS total_sales 
from coffee_sales
where month(transaction_date)=5
group by 1;

-- calculate total sales by location

SELECT 
	store_location,
	concat(round(sum(unit_price * transaction_qty)/1000,2),'K') as Total_Sales
FROM coffee_sales
WHERE
	MONTH(transaction_date) =3
GROUP BY store_location
ORDER BY 1  asc;

-- top 10 products 

select product_type,round(sum(unit_price * transaction_qty),1) as total_sales_by_product
from coffee_sales
where month(transaction_date) = 5
group by product_type
order by 2 desc limit 10;

-- Average sales for particular month
SELECT AVG(total_sales) AS average_sales
FROM (
    SELECT 
        SUM(unit_price * transaction_qty) AS total_sales
    FROM 
        coffee_sales
	WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        transaction_date
) AS internal_query;

-- daily sales for specific month
SELECT 
    DAY(transaction_date) AS day_of_month,
    ROUND(SUM(unit_price * transaction_qty),1) AS total_sales
FROM 
    coffee_sales
WHERE 
    MONTH(transaction_date) = 5  -- Filter for May
GROUP BY 
    1
ORDER BY 
    1;

-- COMPARING DAILY SALES WITH AVERAGE SALES – IF GREATER THAN “ABOVE AVERAGE” and LESSER THAN “BELOW AVERAGE”

SELECT day_of_month,
    CASE 
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_status,
    total_sales
FROM (
    SELECT 
        DAY(transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM 
        coffee_sales
    WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        DAY(transaction_date)
) AS sales_data
ORDER BY 
    day_of_month;
-- sales by product category
SELECT 
	product_category,
	ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_sales
WHERE
	MONTH(transaction_date) = 5 
GROUP BY product_category
ORDER BY SUM(unit_price * transaction_qty) DESC

-- sales by day by hour

SELECT 
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales,
    SUM(transaction_qty) AS Total_Quantity,
    COUNT(*) AS Total_Orders
FROM 
    coffee_sales
WHERE 
    DAYOFWEEK(transaction_date) = 2 -- Filter for Tuesday (1 is Sunday, 2 is Monday, ..., 7 is Saturday)
    AND HOUR(transaction_time) = 8 -- Filter for hour number 8
    AND MONTH(transaction_date) = 5; -- Filter for May (month number 5)

-- 

SELECT 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END AS Day_of_Week,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM 
    coffee_sales
WHERE 
    MONTH(transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY 1;

-- TO GET SALES FOR ALL HOURS FOR MONTH OF MAY
SELECT 
    HOUR(transaction_time) AS Hour_of_Day,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM 
    coffee_sales
WHERE 
    MONTH(transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY 
    1
ORDER BY 
    1;
   
    
    
    
    


















