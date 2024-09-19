-- clean table customer_orders
CREATE TEMPORARY TABLE customer_orders_clean (
  SELECT
    order_id
    , customer_id
    , pizza_id
    , CASE
        WHEN exclusions = 'null' OR exclusions ='' THEN NULL
        ELSE exclusions
        END AS exclusions
    , CASE
        WHEN extras = 'null' OR extras = '' THEN NULL
        ELSE extras
        END AS extras
    , order_time
  FROM customer_orders o
  --   JOIN pizza_recipes p ON o.pizza_id = p.pizza_id
  )
;

-- clean table runner_orders
CREATE TEMPORARY TABLE runner_orders_clean (
  SELECT 
    order_id
    , runner_id
    , CASE
        WHEN pickup_time = 'null' THEN NULL
        ELSE pickup_time
        END AS pickup_time
    , CASE
        WHEN distance = 'null' THEN NULL
        WHEN LOCATE('km', distance) > 0 THEN REPLACE(distance,'km','') * 1
        ELSE distance * 1
        END AS distance
    , CASE
        WHEN duration = 'null' THEN NULL
        WHEN LOCATE('minutes',duration) > 1 THEN REPLACE(duration,'minutes','') * 1
        WHEN LOCATE('minute',duration) > 1 THEN REPLACE(duration,'minute','') * 1
        WHEN LOCATE('mins',duration) > 1 THEN REPLACE(duration,'mins','') * 1
        WHEN LOCATE('min',duration) > 1 THEN REPLACE(duration,'min','') * 1
        ELSE duration * 1
        END AS duration
      , CASE
          WHEN cancellation = 'null' OR cancellation = '' THEN NULL
          ELSE cancellation
        END AS cancellation
  FROM runner_orders
)
;

-- A. PIZZA METRICS
-- 1. How many pizzas were ordered?
SELECT
  COUNT(pizza_id) AS quantity_sold
FROM customer_orders_clean
;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS orders_num
FROM customer_orders_clean
;

-- 3. How many successful orders were delivered by each runner?
SELECT
  r.runner_id
	, COUNT(CASE WHEN ro.pickup_time IS NOT NULL THEN ro.order_id ELSE NULL END) AS orders_num
FROM runners r
  LEFT JOIN runner_orders_clean ro ON r.runner_id = ro.runner_id
GROUP BY 1
;

-- 4. How many of each type of pizza was delivered?
-- only calculate for successful orders
SELECT
	p.pizza_id
	, p.pizza_name
	, COUNT(c.pizza_id) AS pizzas_num
FROM customer_orders_clean c
	JOIN pizza_names p ON c.pizza_id = p.pizza_id
	JOIN runner_orders_clean r ON c.order_id = r.order_id AND r.pickup_time IS NOT NULL
GROUP BY 1,2
;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
	c.customer_id
	, COUNT(CASE WHEN p.pizza_name = 'Vegetarian' THEN c.pizza_id ELSE NULL END) AS vegetarian_pizza_ordered
	, COUNT(CASE WHEN p.pizza_name = 'Meatlovers' THEN c.pizza_id ELSE NULL END) AS meatlovers_pizza_ordered
FROM customer_orders_clean c
	JOIN pizza_names p ON c.pizza_id = p.pizza_id
	JOIN runner_orders_clean r ON c.order_id = r.order_id -- AND r.pickup_time IS NOT NULL
GROUP BY 1
;

-- 6. What was the maximum number of pizzas delivered in a single order?
-- only calculate for successful orders
SELECT
	r.order_id
	, count(pizza_id) AS quantity_sold
FROM customer_orders_clean c
	JOIN runner_orders_clean r ON c.order_id = r.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY 1
ORDER BY count(pizza_id) DESC
LIMIT 1
;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- only calculate for successful orders
SELECT
	c.customer_id
	, COUNT(CASE WHEN c.exclusions IS NOT NULL OR extras IS NOT NULL THEN c.pizza_id ELSE NULL END) AS delivered_pizzas_with_changes
	, COUNT(CASE WHEN c.exclusions IS NULL AND extras IS NULL THEN c.pizza_id ELSE NULL END) AS delivered_pizzas_with_no_changes
FROM customer_orders_clean c
	JOIN runner_orders_clean r ON c.order_id = r.order_id AND r.pickup_time IS NOT NULL
GROUP BY 1
;

-- 8. How many pizzas were delivered that had both exclusions and extras?
-- only calculate for successful orders
SELECT
	COUNT(pizza_id) AS delivered_pizza_w_exclusions_extras
FROM customer_orders_clean c
	JOIN runner_orders_clean r ON c.order_id = r.order_id AND r.pickup_time IS NOT NULL
WHERE exclusions IS NOT NULL AND extras IS NOT NULL
;

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT
	HOUR(order_time) AS order_hour
	, COUNT(pizza_id) AS total_pizzas
FROM customer_orders_clean c
	JOIN runner_orders_clean r ON c.order_id = r.order_id -- AND r.pickup_time IS NOT NULL
GROUP BY 1
ORDER BY 1
;

-- 10. What was the volume of orders for each day of the week?
SELECT
	DAYOFWEEK(c.order_time) AS dayweek
	, CASE
		   WHEN DAYOFWEEK(c.order_time) = 1 THEN 'Sunday'
		   WHEN DAYOFWEEK(c.order_time) = 2 THEN 'Monday'
		   WHEN DAYOFWEEK(c.order_time) = 3 THEN 'Tuesday'
		   WHEN DAYOFWEEK(c.order_time) = 4 THEN 'Wednesday'
		   WHEN DAYOFWEEK(c.order_time) = 5 THEN 'Thursday'
		   WHEN DAYOFWEEK(c.order_time) = 6 THEN 'Friday'
		   WHEN DAYOFWEEK(c.order_time) = 7 THEN 'Saturday'
			 END AS day_of_week
	, COUNT(DISTINCT c.order_id) AS total_orders
FROM customer_orders_clean c
	JOIN runner_orders_clean r ON c.order_id = r.order_id -- r.pickup_time IS NOT NULL
GROUP BY 1,2
ORDER BY 1
;

-- 11. Compare orders with extra toppings with orders no topping
SELECT
		IF( c.extras IS NOT NULL, 'orders_w_topping', 'orders_w_no_topping') AS order_type
	, COUNT(DISTINCT r.order_id) AS orders_num
FROM customer_orders_clean c
	JOIN runner_orders_clean r ON c.order_id = r.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY 1
;


-- B. RUNNER AND CUSTOMER EXPERIENCE

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
	WEEK(registration_date, 5) + 1 AS week
	, COUNT(runner_id) AS runner_num
from runners
GROUP BY 1
;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT
	r.runner_id
	, AVG( TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time) ) AS avg_pickup_minute
FROM runner_orders_clean r
	JOIN customer_orders_clean c ON r.order_id = c.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY 1
;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH max_pickup_minute AS (
	SELECT
		r.order_id
		, COUNT(pizza_id) AS pizza_num
		, MAX( TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time) ) AS max_pickup_minute
		
	FROM runner_orders_clean r
		JOIN customer_orders_clean c ON r.order_id = c.order_id
	WHERE r.pickup_time IS NOT NULL
	GROUP BY 1
	ORDER BY 1
)
SELECT
	pizza_num
	, AVG(max_pickup_minute) AS avg_pickup_minute
FROM max_pickup_minute
GROUP BY 1
;

-- 4. What was the average distance travelled for each customer?
SELECT
	c.customer_id
	, ROUND(AVG(distance), 2) AS avg_distance
FROM runner_orders_clean r
	JOIN customer_orders_clean c ON r.order_id = c.order_id
WHERE pickup_time IS NOT NULL
GROUP BY 1
;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT
	MAX(duration) - MIN(duration) AS duration_diff
FROM runner_orders_clean
WHERE pickup_time IS NOT NULL
;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
	runner_id
	, AVG( distance / duration ) AS avg_speed
FROM runner_orders_clean
WHERE pickup_time IS NOT NULL
GROUP BY 1
;

-- 7. What is the successful delivery percentage for each runner?
SELECT
	runner_id
	, COUNT(order_id) AS all_orders
	, COUNT(CASE WHEN pickup_time IS NOT NULL THEN order_id ELSE NULL END) AS successful_orders
	, ROUND( COUNT(CASE WHEN pickup_time IS NOT NULL THEN order_id ELSE NULL END) / COUNT(order_id) * 100, 0) AS successful_delivery_pct
FROM runner_orders_clean
GROUP BY 1
;

-- C. INGREDIENT OPTIMISATION
-- 1. What are the standard ingredients for each pizza?
WITH RECURSIVE toppingCTE AS (
	-- Lấy tất cả các pizza và phần đầu tiên của chuỗi toppings
	SELECT
		pizza_id
		, SUBSTRING_INDEX(toppings, ',', 1) AS topping_id
		, SUBSTRING(toppings, INSTR(toppings, ',') + 1) AS remaining_toppings
	FROM pizza_recipes
	WHERE toppings LIKE '%,%'
	
	UNION ALL
	
	-- Tách các giá trị toppings còn lại trong chuỗi
	SELECT
		pizza_id
		, SUBSTRING_INDEX(remaining_toppings, ',', 1) AS topping_id
		, SUBSTRING( remaining_toppings, INSTR(remaining_toppings, ',') +1 ) AS remaining_toppings
	FROM toppingCTE
	WHERE remaining_toppings LIKE '%,%'
	
	UNION ALL
	
	-- Lấy giá trị cuối cùng khi không còn dấu phẩy
	SELECT
		pizza_id
		, remaining_toppings AS topping_id
		, NULL AS remaining_toppings
	FROM toppingCTE
	WHERE remaining_toppings NOT LIKE '%,%'
)
SELECT
	cte.pizza_id
	, n.pizza_name
	, GROUP_CONCAT(topping_name SEPARATOR ', ') AS toppings
FROM toppingCTE cte
	JOIN pizza_toppings t ON TRIM(cte.topping_id) = t.topping_id
	JOIN pizza_names n ON cte.pizza_id = n.pizza_id
GROUP BY 1,2
ORDER BY 1,2
;

-- 2. What was the most commonly added extra?
CREATE TEMPORARY TABLE temp_customer_orders AS
	SELECT
		order_id
		, pizza_id
		, extras AS extra_topping_id
	FROM customer_orders_clean
	WHERE extras IS NOT NULL AND LOCATE(',', extras) = 0
;

CREATE TEMPORARY TABLE temp_extra_toppings AS
  WITH RECURSIVE extra_toppingsCTE AS (
    SELECT
      order_id
      , pizza_id
      , SUBSTRING_INDEX(extras, ',', 1) AS topping_id
      , SUBSTRING(extras, INSTR(extras, ',') +1 ) AS remaining_toppings
    FROM customer_orders_clean
    WHERE extras LIKE '%,%'
    
    UNION ALL
    
    SELECT
      order_id
      , pizza_id
      , SUBSTRING_INDEX(remaining_toppings, ',', 1) AS topping_id
      , SUBSTRING(remaining_toppings, INSTR(remaining_toppings, ',') +1) AS remaining_toppings
    FROM extra_toppingsCTE
    WHERE remaining_toppings LIKE '%,%'
    
    UNION ALL
    
    SELECT
      order_id
      , pizza_id
      , remaining_toppings AS topping_id
      , NULL AS remaining_toppings
    FROM extra_toppingsCTE
    WHERE remaining_toppings NOT LIKE '%,%'
    )
SELECT *
FROM extra_toppingsCTE;

-- Get most common extra topping
SELECT
	extra_topping_id
	, COUNT(extra_topping_id) AS extra_topping_num
FROM (
	SELECT
		order_id
		, pizza_id
		, TRIM(topping_id) AS extra_topping_id
	FROM temp_extra_toppings

	UNION ALL

	SELECT *
	FROM temp_customer_orders

	ORDER BY 1
	) tbl
GROUP BY 1
ORDER BY 2 DESC
;

-- 3. What was the most common exclusion?
CREATE TEMPORARY TABLE temp_customer_orders_exclusion AS
	SELECT
		order_id
		, pizza_id
		, exclusions
	FROM customer_orders_clean
	WHERE exclusions IS NOT NULL AND LOCATE(',' , exclusions) = 0
;

CREATE TEMPORARY TABLE temp_exclusion_toppings AS
WITH RECURSIVE exclusion_toppingsCTE AS (
		SELECT
			order_id
			, pizza_id
			, SUBSTRING_INDEX(exclusions, ',', 1) AS topping_id
			, SUBSTRING(exclusions, INSTR(exclusions, ',') +1 ) AS remaining_toppings
		FROM customer_orders_clean
		WHERE exclusions LIKE '%,%'
		
		UNION ALL
		
		SELECT
			order_id
			, pizza_id
			, SUBSTRING_INDEX(remaining_toppings, ',', 1) AS topping_id
			, SUBSTRING(remaining_toppings, INSTR(remaining_toppings, ',') +1) AS remaining_toppings
		FROM exclusion_toppingsCTE
		WHERE remaining_toppings LIKE '%,%'
		
		UNION ALL
		
		SELECT
			order_id
			, pizza_id
			, remaining_toppings AS topping_id
			, NULL AS remaining_toppings
		FROM exclusion_toppingsCTE
		WHERE remaining_toppings NOT LIKE '%,%'
	)
SELECT * 
FROM exclusion_toppingsCTE
;

-- Get most common exclusion toppings
SELECT
	exlusions_topping_id
	, COUNT(exlusions_topping_id) AS  exclusion_topping_num
FROM (
	SELECT
		order_id
		, pizza_id
		, TRIM(topping_id) AS exlusions_topping_id
	FROM temp_exclusion_toppings

	UNION ALL

	SELECT *
	FROM temp_customer_orders_exclusion

	ORDER BY 1) tbl
GROUP BY 1
ORDER BY 2 DESC
;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

-- STEPS:
-- 1. Lấy tất cả các pizza có cả extra topping và exclusion topping
-- 2. Lấy tất cả các pizza có extra topping nhưng không có exclusion topping
-- 3. Lấy tất cả các pizza có exclusion topping nhưng không có extra topping
-- 4. Lấy tất cả các pizza không có extra topping và không có topping loại trừ
-- 5. UNION ALL các bước trên: 1, 2, 3, 4


-- 1. Lấy tất cả các pizza có cả extra topping và exclusion topping
WITH pizza_with_extra_toppings_cte AS (
	SELECT
		e.order_id
		, e.pizza_id
		, GROUP_CONCAT(t.topping_name SEPARATOR ', ') AS extra_topping_name
	FROM temp_extra_toppings e
		JOIN pizza_toppings t ON e.topping_id = t.topping_id
	GROUP BY 1,2

	UNION ALL

	SELECT
		c.order_id
		, c.pizza_id
		, t.topping_name
	FROM customer_orders c
		JOIN pizza_toppings t ON c.extras = t.topping_id
	WHERE LOCATE(',', c.extras) = 0 -- AND c.exclusions IS NULL 
	),
pizza_with_exclusion_toppings_cte AS (
		SELECT
			c.order_id
			, c.pizza_id
			, t.topping_name AS exclusion_topping
		FROM customer_orders c
			JOIN pizza_toppings t ON c.exclusions = t.topping_id
		WHERE LOCATE(',', exclusions) = 0 -- AND c.extras IS NULL

		UNION ALL

		SELECT
			e.order_id
			, e.pizza_id
			, GROUP_CONCAT(t.topping_name SEPARATOR ', ') AS exlusion_topping
		FROM temp_exclusion_toppings e
			JOIN pizza_toppings t ON e.topping_id = t.topping_id
		GROUP BY 1,2
)
SELECT
	extra.order_id
	, extra.pizza_id
	, extra.extra_topping_name
	, exclusion.exclusion_topping
	, CONCAT( pizza_name, ' - ', 'Extra ', extra_topping_name, ' - ', 'Exclude ', exclusion_topping) AS full_note
FROM pizza_with_extra_toppings_cte extra
JOIN pizza_with_exclusion_toppings_cte exclusion 
    ON extra.order_id = exclusion.order_id 
    AND extra.pizza_id = exclusion.pizza_id
JOIN pizza_names n ON extra.pizza_id = n.pizza_id

UNION ALL

-- 2. Lấy tất cả các pizza có extra topping nhưng không có exclusion topping
SELECT
		c.order_id
		, c.pizza_id
		, t.topping_name AS extra_topping_name
		, '' AS exclusion_topping
		, CONCAT( n.pizza_name, ' - ', 'Extra ', t.topping_name) AS full_note
FROM customer_orders c
	JOIN pizza_toppings t ON c.extras = t.topping_id
	JOIN pizza_names n ON c.pizza_id = n.pizza_id
WHERE LOCATE(',', c.extras) = 0 -- AND c.exclusions IS NULL 

UNION ALL

-- 3. Lấy tất cả các pizza có exclusion topping nhưng không có extra topping
SELECT
		c.order_id
		, c.pizza_id
		, '' AS extra_topping
		, t.topping_name AS exclusions_topping_name
		, CONCAT( n.pizza_name, ' - ', 'Exclude ', t.topping_name) AS full_note
FROM customer_orders c
	JOIN pizza_toppings t ON c.exclusions = t.topping_id
	JOIN pizza_names n ON c.pizza_id = n.pizza_id
WHERE LOCATE(',', c.exclusions) = 0 AND c.extras = ''

UNION ALL

-- 4. Lấy tất cả các pizza không có extra topping và không có topping loại trừ
SELECT
	c.order_id
	, c.pizza_id
	, '' AS extra_topping_name
	, '' AS exclusion_topping
	, n.pizza_name AS full_note
FROM customer_orders_clean c
	JOIN pizza_names n ON c.pizza_id = n.pizza_id
WHERE exclusions IS NULL AND extras IS NULL

-- order by
ORDER BY 1,2
;

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

-- Steps:
-- 1. Tạo nên bảng tạm full_toppings với tất cả standard toppings và extra toppings
-- 2. Tách các topping từ cột full_topping và mapping với tên topping
-- 3. Tính số lần xuất hiện của từng topping và nối với tên topping


-- 1. Tạo nên bảng tạm full_toppings với tất cả standard toppings và extra toppings
CREATE TEMPORARY TABLE full_toppings AS
	SELECT
		c.order_id
		, c.pizza_id
	-- 	, r.toppings
	-- 	, c.extras
		, IF(c.extras IS NULL, r.toppings, CONCAT(r.toppings, ', ', c.extras) ) AS full_topping
	FROM customer_orders_clean c
		JOIN pizza_recipes r ON c.pizza_id = r.pizza_id 
;

-- 2. Tách các topping từ cột full_topping và mapping với tên topping
WITH RECURSIVE toppingCTE AS (
    -- Tách các topping từ cột full_topping và mapping với tên topping
    SELECT
				order_id
				, pizza_id
        , full_topping
        , SUBSTRING_INDEX(full_topping, ',', 1) AS topping_id
        , SUBSTRING(full_topping, INSTR(full_topping, ',') + 1) AS remaining_toppings
    FROM full_toppings
    WHERE full_topping LIKE '%,%'
    
    UNION ALL
		
    -- Tách các giá trị toppings còn lại trong chuỗi
    SELECT
				order_id
				, pizza_id
        , tc.full_topping
        , SUBSTRING_INDEX(tc.remaining_toppings, ',', 1) AS topping_id
        , SUBSTRING(tc.remaining_toppings, INSTR(tc.remaining_toppings, ',') + 1) AS remaining_toppings
    FROM toppingCTE tc
    WHERE tc.remaining_toppings LIKE '%,%'
    
    UNION ALL
    
    -- Lấy giá trị cuối cùng khi không còn dấu phẩy
    SELECT 
				order_id
				, pizza_id
        , tc.full_topping
        , tc.remaining_toppings AS topping_id
        , NULL AS remaining_toppings
    FROM toppingCTE tc
    WHERE tc.remaining_toppings NOT LIKE '%,%'
)

SELECT 
	order_id
	, pizza_id
	, GROUP_CONCAT(final_topping_display SEPARATOR ', ') AS final_topping_display
FROM (
		-- 3. Tính số lần xuất hiện của từng topping và nối với tên topping
		SELECT 
				order_id
				, pizza_id
				, t.topping_name
				, COUNT(tc.topping_id) AS topping_count
				, CASE 
							WHEN COUNT(tc.topping_id) > 1 THEN CONCAT(COUNT(tc.topping_id), ' x ', t.topping_name)
							ELSE t.topping_name
					END AS final_topping_display
		FROM ToppingCTE tc
		JOIN pizza_toppings t ON tc.topping_id = t.topping_id
		GROUP BY 1,2,3
		) final_topping_display_tbl
GROUP BY 1,2
ORDER BY 1,2
;

-- D. PRICING AND RATINGS
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT
	c.pizza_id
	, n.pizza_name
	, SUM( IF(c.pizza_id = 1, 12, 10) ) AS total_sales
FROM customer_orders_clean c
	JOIN pizza_names n ON c.pizza_id = n.pizza_id
	JOIN runner_orders_clean r ON c.order_id = r.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY 1,2
;

-- 2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
SELECT
	c.order_id
	, c.pizza_id
	, n.pizza_name
	, SUM(
			IF(c.pizza_id = 1, 12, 10) +
			IFNULL( LENGTH(c.extras) - LENGTH(REPLACE(c.extras, ',', '')) +1, 0)
			) AS total_price
FROM customer_orders_clean c
	JOIN pizza_names n ON c.pizza_id = n.pizza_id
	JOIN runner_orders_clean r ON c.order_id = r.order_id
WHERE r.pickup_time IS NOT NULL
GROUP BY 1,2,3
;


-- 3. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
SELECT
    c.order_id
    , ROUND(
		SUM(
        IF(c.pizza_id = 1, 12, 10) + 
        IFNULL(LENGTH(c.extras) - LENGTH(REPLACE(c.extras, ',', '')) + 1, 0)
    ) - SUM(IFNULL(r.distance * 0.30, 0))
		,2
		) AS net_total
FROM runner_orders_clean r
JOIN customer_orders_clean c ON r.order_id = c.order_id
JOIN pizza_names n ON c.pizza_id = n.pizza_id
WHERE r.pickup_time IS NOT NULL
GROUP BY c.order_id
;
