/*Joining tables to see when pizzas were ordered, what types of pizza, and the cost of each pizza ordered */

WITH joined_pizza_table AS (
SELECT o.order_id,
	   od.quantity,
	   date,
	   DATETRUNC(hour,time) AS hour_ordered,
	   p.pizza_id, pt.pizza_type_id,
	   ROUND(p.price,2) AS price_two_decimals,
	   pt.category

FROM orders AS o
LEFT JOIN order_details AS od
	ON o.order_id = od.order_id
LEFT JOIN pizzas AS p
	ON od.pizza_id = p.pizza_id
LEFT JOIN pizza_types AS pt
	ON p.pizza_type_id = pt.pizza_type_id)


/*Query to discover the best selling pizzas.*/
SELECT pizza_type_id,
	   ROUND(SUM(price_two_decimals*quantity),2) AS pizza_type_rev
FROM joined_pizza_table
GROUP BY pizza_type_id
ORDER BY pizza_type_rev DESC

/*Query to find the best selling categories of pizza, number of pizzas in each category, and average revenue per pizza.
*/

SELECT category,
	   ROUND(SUM(price_two_decimals*quantity),2) AS category_rev,
	   COUNT(DISTINCT pizza_type_id) AS num_in_category,
	   ROUND(SUM(price_two_decimals*quantity)/COUNT(DISTINCT pizza_type_id),2) AS average_rev_per_pizza
FROM joined_pizza_table
GROUP BY category
ORDER BY category_rev DESC


-- Joining order tables and order details tables

WITH orders_by_hour AS (
SELECT o.order_id, 
       od.quantity,
	   date, 
	   DATETRUNC(hour,time) AS hour_ordered,
	   p.pizza_id, 
	   ROUND(p.price,2) AS price_two_decimals
FROM orders AS o
LEFT JOIN order_details AS od
	ON o.order_id = od.order_id
LEFT JOIN pizzas AS p
	ON od.pizza_id = p.pizza_id),

--CTE returning revenue per day for every day of sales
revenue_per_day AS (
SELECT date, 
	   SUM(price_two_decimals*quantity) AS revenue_per_day
FROM orders_by_hour
GROUP BY date

--CTE returning revenue per hour
total_rev_each_hour AS (
SELECT date,
	   hour_ordered,
	   SUM(price_two_decimals*quantity) AS rev_on_day_in_hour, 
	   COUNT(DISTINCT order_id) AS num_of_orders
FROM orders_by_hour
GROUP BY date, hour_ordered
)

--Query outputs the avg hourly revenue throughout the year
SELECT hour_ordered,
	   ROUND(AVG(rev_on_day_in_hour),2) AS avg_hourly_rev,
	   SUM(num_of_orders) AS total_orders_in_hour
FROM total_rev_each_hour
GROUP BY hour_ordered
ORDER BY hour_ordered



/*Query displaying total revenue made on each day of the week, and avg revenue for each day.
*/

SELECT *, 
       ROUND(revenue_per_day/days_open, 2) AS avg_dow_rev
FROM revenue_per_day
ORDER BY avg_dow_rev DESC;

SELECT o.order_id,
	   od.quantity, 
	   date, 
	   DATENAME(WEEKDAY, date) AS DN,
	   DATETRUNC(hour,time) AS hour_ordered,
	   p.pizza_id, ROUND(p.price,2) AS price_two_decimals

FROM orders AS o
LEFT JOIN order_details AS od
	ON o.order_id = od.order_id
LEFT JOIN pizzas AS p
	ON od.pizza_id = p.pizza_id;

WITH orders_by_hour AS (
SELECT o.order_id,
       od.quantity, date, 
	   DATENAME(WEEKDAY, date) AS DN, 
	   DATETRUNC(hour,time) AS hour_ordered, 
	   p.pizza_id, 
	   ROUND(p.price,2) AS price_two_decimals

FROM orders AS o
JOIN order_details AS od
ON o.order_id = od.order_id
JOIN pizzas AS p
ON od.pizza_id = p.pizza_id)

SELECT count(*)
from orders_by_hour;


--Table returning only dates with a higher than avg daily revenue
SELECT date, 
       revenue_per_day, 
	(SELECT ROUND(AVG(revenue_per_day),2)
	FROM revenue_per_day) AS avg_daily_revenue	
	
FROM revenue_per_day
WHERE revenue_per_day >= (
	SELECT AVG(revenue_per_day)
	FROM revenue_per_day)
ORDER BY date;