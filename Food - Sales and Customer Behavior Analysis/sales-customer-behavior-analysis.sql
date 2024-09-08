-- 1. What is the total amount each customer spent at the restaurant?
SELECT
  customer_id
  , SUM( price ) AS total_sales 
FROM
  sales s
  LEFT JOIN menu m ON s.product_id = m.product_id 
GROUP BY
  1;

-- 2. How many days has each customer visited the restaurant?
SELECT
  customer_id
  , COUNT( DISTINCT order_date ) AS visit_num 
FROM
  sales 
GROUP BY
  1;
  
-- 3. What was the first item from the menu purchased by each customer?
SELECT DISTINCT
  min_date.customer_id
  , min_date.order_date
  , min_date.product_id
  , menu.product_name AS first_ordered_product
FROM
  ( 
  SELECT 
    *
    , RANK() over ( PARTITION BY customer_id ORDER BY order_date ) AS ranking 
  FROM sales 
	) min_date
LEFT JOIN menu ON min_date.product_id = menu.product_id
WHERE min_date.ranking = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
	m.product_id
	, m.product_name
	, COUNT(s.product_id) AS quantity_sold
FROM menu m
	LEFT JOIN sales s ON m.product_id = s.product_id
GROUP BY 1,2
ORDER BY 3 DESC
;

-- 5. Which item was the most popular for each customer?
SELECT *
FROM (
	SELECT
		*
		, RANK() OVER (PARTITION BY customer_id ORDER BY purchase_num DESC) AS rnk
	FROM (
		SELECT
			s.customer_id
			, s.product_id
			, COUNT(product_id) AS purchase_num
		FROM sales s
		GROUP BY 1,2
		ORDER BY 1, 3 DESC
		) quantity_sold
		) tbl
WHERE rnk=1
;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT
	m.customer_id
	, m.join_date
	, s.order_date
	, s.product_id
	, mn.product_name
FROM members m
	JOIN sales s ON m.customer_id = s.customer_id
	JOIN menu mn ON s.product_id = mn.product_id
WHERE s.order_date >= m.join_date
ORDER BY 1, 2, 3
;

-- 7. Which item was purchased just before the customer became a member?
SELECT
	m.customer_id
	, m.join_date
	, s.order_date
	, s.product_id
	, mn.product_name
FROM members m
	JOIN sales s ON m.customer_id = s.customer_id
	JOIN menu mn ON s.product_id = mn.product_id
WHERE m.join_date > s.order_date
ORDER BY 1,2,3
;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
	m.customer_id
-- 	, s.product_id
	, COUNT(s.product_id) AS total_items
	, SUM(mn.price) AS total_sales
FROM members m
	JOIN sales s ON m.customer_id = s.customer_id
	JOIN menu mn ON s.product_id = mn.product_id
WHERE s.order_date >= m.join_date
GROUP BY 1
ORDER BY 1
;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
	customer_id
	, SUM(points) AS total_points
FROM (
	SELECT
		m.customer_id
		, product_name
		, SUM(price) AS total_sales
		, CASE 
				WHEN product_name = "sushi" THEN SUM(price) * 10 * 2
				ELSE SUM(price) * 10
			END AS points
	FROM members m
		JOIN sales s ON m.customer_id = s.customer_id
		JOIN menu mn ON s.product_id = mn.product_id
	GROUP BY 1,2
	ORDER BY 1,2
	) points
GROUP BY 1
;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
	m.customer_id
	, s.product_id
	, mn.product_name
	, m.join_date
	, DATE_ADD(m.join_date,INTERVAL 7 DAY) AS end_first_week
	, SUM(price) AS total_sales
	, SUM(price) * 10 * 2 AS total_points
FROM members m
	JOIN sales s ON m.customer_id = s.customer_id
	JOIN menu mn ON s.product_id = mn.product_id
WHERE s.order_date BETWEEN m.join_date AND DATE_ADD(m.join_date,INTERVAL 7 DAY)
GROUP BY 1,2,3,4,5
ORDER BY 1
;

-- 11. Create a table with columns: customer_id, order_date, product_name, price, member (Y/N)
SELECT
	s.customer_id
	, s.order_date
	, mn.product_name
	, mn.price
	, CASE 
	WHEN join_date IS NULL THEN "N"
	WHEN order_date >= join_date THEN "Y"
	ELSE "N"
	END AS member

FROM sales s
	LEFT JOIN menu mn ON s.product_id = mn.product_id
	LEFT JOIN members m ON s.customer_id = m.customer_id
ORDER BY 1,2,4 desc
;

-- 12. From answer 11, adding new column: ranking
WITH sales_info AS (
	SELECT
		s.customer_id
		, s.order_date
		, mn.product_name
		, mn.price
		, CASE 
				WHEN m.join_date IS NULL THEN "N"
				WHEN s.order_date >= join_date THEN "Y"
				ELSE "N"
				END AS member

	FROM sales s
		LEFT JOIN menu mn ON s.product_id = mn.product_id
		LEFT JOIN members m ON s.customer_id = m.customer_id
	ORDER BY 1,2,4 DESC
)

SELECT
	*
	, '' AS ranking
FROM sales_info
WHERE member = "N"

UNION ALL

SELECT
	*
-- 	, CASE
-- 			WHEN member = "N" THEN ""
-- 			WHEN when_value THEN
-- 		ELSE END AS ranking
	, RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date) AS rnk
FROM sales_info
WHERE member = "Y"

ORDER BY 1,2,3,4
;