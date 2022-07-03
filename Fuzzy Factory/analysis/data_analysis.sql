USE mavenfuzzyfactory;

/*
1. Gsearch seems to be the biggest driver of our business.
Could you pull monthly trends for gsearch sessions, orders and conversion rate so that we can showcase the growth there?
*/
SELECT
	DATE_FORMAT(ws.created_at, '%b') AS month,
    COUNT(website_session_id) AS total_sessions,
    COUNT(order_id) AS total_orders,
    COUNT(order_id) / COUNT(website_session_id) AS session_to_order_cvr
FROM website_sessions ws
	LEFT JOIN orders o USING (website_session_id)
WHERE
	ws.utm_source = 'gsearch'
    AND ws.created_at < '2012-11-27'
GROUP BY
	month
;

/*
2. Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand and
brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell.
*/

SELECT
	MONTHNAME(ws.created_at) AS month,
    COUNT(CASE WHEN utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_sessions,
    COUNT(CASE WHEN utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbrand_sessions,
    COUNT(CASE WHEN utm_campaign = 'brand' THEN o.order_id ELSE NULL END) AS brand_orders,
    COUNT(CASE WHEN utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) AS nonbrand_orders,
    COUNT(CASE WHEN utm_campaign = 'brand' THEN o.order_id ELSE NULL END) 
		/ COUNT(CASE WHEN utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_cvr,
	COUNT(CASE WHEN utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) 
		/ COUNT(CASE WHEN utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbrand_cvr
FROM website_sessions ws
	LEFT JOIN orders o USING (website_session_id)
WHERE
	ws.created_at < '2012-11-27'
	AND utm_source = 'gsearch'
GROUP BY
	month
;

/*
3. While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device
type? I want to flex our analytical muscles a little and show the board we really know our traffic sources.
*/
SELECT
	DATE_FORMAT(ws.created_at, '%b') AS month,
    COUNT(CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_sesisons,
    COUNT(CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions,
    COUNT(CASE WHEN device_type = 'desktop' THEN order_id ELSE NULL END) AS desktop_orders,
    COUNT(CASE WHEN device_type = 'mobile' THEN order_id ELSE NULL END) AS mobile_orders,
    COUNT(CASE WHEN device_type = 'desktop' THEN order_id ELSE NULL END)
		/ COUNT(CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_cvr,
	COUNT(CASE WHEN device_type = 'mobile' THEN order_id ELSE NULL END)
		/ COUNT(CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_cvr
FROM website_sessions ws
	LEFT JOIN orders o USING (website_session_id)
WHERE
	ws.created_at < '2012-11-27'
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY
	month
;

/*
4. I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from Gsearch. 
Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?
*/

-- Finding various source and referer to see the traffic
SELECT
	DISTINCT utm_source,
    utm_campaign,
    http_referer
FROM website_sessions
WHERE
	created_at < '2012-11-27'
;

SELECT
	DATE_FORMAT(created_at, '%b') AS month,
    COUNT(CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_paid_sessions,
    COUNT(CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch_paid_sessions,
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END) AS direct_type_in_sessions,
	COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END) AS organic_search
FROM website_sessions
WHERE
	created_at < '2012-11-27'
GROUP BY
	month
;

/*
5. I’d like to tell the story of our website performance improvements over the course of the first 8 months. 
Could you pull session to order conversion rates, by month?
*/

SELECT
	DATE_FORMAT(ws.created_at, '%b') AS month,
    COUNT(ws.website_session_id) AS total_sessions,
    COUNT(order_id) AS total_orders,
    COUNT(order_id) / COUNT(ws.website_session_id) AS session_to_order_cvr
FROM website_sessions ws
	LEFT JOIN orders o USING(website_session_id)
WHERE
	ws.created_at < '2012-11-27'
GROUP BY
	month
;

/*
6. For the gsearch lander test, please estimate the revenue that test earned us
(Hint: Look at the increase in CVR from the test (Jun 19 – Jul 28), 
and use nonbrand sessions and revenue since then to calculate incremental value)
*/

-- find first test pageview id
SELECT
	MIN(website_pageview_id) AS first_test_pv_id -- rs = 23504
FROM website_pageviews wp
WHERE pageview_url = '/lander-1';

SELECT
	pageview_url,
    COUNT(ws.website_session_id) AS total_sessions,
    COUNT(o.order_id) AS total_orders,
	COUNT(o.order_id) / COUNT(ws.website_session_id) AS conversion_rate
FROM website_sessions ws
	LEFT JOIN website_pageviews wp USING (website_session_id)
    LEFT JOIN orders o USING (website_session_id)
WHERE
	wp.created_at < '2012-07-28'
	AND website_pageview_id >= 23504
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
    AND pageview_url IN ('/home', '/lander-1')
GROUP BY
	pageview_url
;

-- 0.0318 for /home, vs 0.0406 for /lander-1
-- 0.0088 additional orders per session

-- finding the most recent pageview nonbrand where the traffic was send to /home
SELECT
	MAX(ws.website_session_id) AS most_recent_gsearch_nonbrand_home_pv -- rs = 17145
FROM website_sessions ws
	LEFT JOIN website_pageviews wp USING (website_session_id)
WHERE
	ws.created_at < '2012-11-27'
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
    AND pageview_url = '/home'
;

SELECT
	COUNT(website_session_id) AS session_since_test -- rs = 22972
FROM website_sessions
WHERE
	created_at < '2012-11-27'
    AND website_session_id > 17145
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
;

-- 22972: website_sessions since test

/*
7. For the landing page test you analyzed previously, it would be great to show a full conversion funnel from each
of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 – Jul 28).
*/

CREATE TEMPORARY TABLE session_level_made_it_flagged_3
SELECT
	website_session_id,
    MAX(homepage) AS saw_homepage,
    MAX(lander_1) AS saw_lander_1,
    MAX(product_page) AS product_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM (
		SELECT
			ws.website_session_id,
			pageview_url,
			-- wp.created_at AS pageview_created_at,
			CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
			CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS lander_1,
			CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS product_page,
			CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
			CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
			CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
			CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
			CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
		FROM website_sessions ws
			LEFT JOIN website_pageviews wp USING (website_session_id)
		WHERE ws.utm_source = 'gsearch' 
			AND ws.utm_campaign = 'nonbrand' 
			AND ws.created_at < '2012-07-28'
				AND ws.created_at > '2012-06-19'
		ORDER BY
			ws.website_session_id,
            wp.created_at
	) AS pageview_level
GROUP BY
	website_session_id;

SELECT
	CASE
		WHEN saw_homepage = 1 THEN 'saw_homepage'
		WHEN saw_lander_1 = 1 THEN 'saw_lander_1'
        ELSE 'oops... check logic'
    END AS segment,
    COUNT(website_session_id) AS total_sessions,
    COUNT(CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(website_session_id) AS clicked_to_products,
    COUNT(CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS clicked_to_mrfuzzy,
    COUNT(CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS clicked_to_cart,
    COUNT(CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS clicked_to_shipping,
    COUNT(CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS clicked_to_billing,
    COUNT(CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS clicked_to_thankyou
    
FROM session_level_made_it_flagged_3
GROUP BY
	segment
;

/*
8. I’d love for you to quantify the impact of our billing test, as well. 
Please analyze the lift generated from the test (Sep 10 – Nov 10), 
in terms of revenue per billing page session, 
and then pull the number of billing page sessions for the past month to understand monthly impact.
*/

SELECT
	pageview_url,
    COUNT(ws.website_session_id) AS total_sessions,
    COUNT(o.order_id) AS total_orders,
    COUNT(o.order_id) / COUNT(ws.website_session_id) AS conversion_rate,
    SUM(price_usd) AS total_revenue,
	SUM(price_usd) / COUNT(o.order_id) AS revenue_per_order,
	SUM(price_usd) / COUNT(ws.website_session_id) AS revenue_per_session
FROM website_sessions ws
	LEFT JOIN website_pageviews wp USING (website_session_id)
    LEFT JOIN orders o USING (website_session_id)
WHERE
		wp.created_at > '2012-09-10'
		AND wp.created_at < '2012-11-10'
		AND pageview_url IN ('/billing', '/billing-2')
GROUP BY
	pageview_url
;

-- 22.83: revenue_per_session page seen for the old version
-- 31.34: revenue_per_session page seen for the new version
-- Lift: 8.51 revenue_per_session


SELECT
	COUNT(website_session_id) AS billing_sessions_past_month, -- rs = 1193
    pageview_url 
FROM website_pageviews
WHERE 
	pageview_url IN ('/billing', '/billing-2')
	AND created_at BETWEEN '2012-10-27' AND '2012-11-27'
GROUP BY pageview_url 
;

-- 1193 billing sessions past month
-- value of billing test: 1193 * 8.51 = $10160 over the past month

/*
9. First, I’d like to show our volume growth. Can you pull overall session and order volume, trended by quarter for the life of the business? 
Since the most recent quarter is incomplete, you can decide how to handle it.
*/
SELECT
	YEAR(ws.created_at) AS year,
	QUARTER(ws.created_at) AS qtr,
    COUNT(DISTINCT ws.website_session_id) AS total_sessions,
    COUNT(DISTINCT order_id) AS total_orders
FROM website_sessions ws
	LEFT JOIN orders o USING (website_session_id)
GROUP BY 1, 2
;

/*
10. Next, let’s showcase all of our efficiency improvements. I would love to show quarterly figures since we launched, 
for session-to-order conversion rate, revenue per order, and revenue per session.
*/

SELECT
	YEAR(ws.created_at) AS year,
    QUARTER(ws.created_at) AS qtr,
	-- COUNT(DISTINCT ws.website_session_id) AS total_sessions,
    -- COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT order_id) / COUNT(DISTINCT ws.website_session_id) AS session_to_order_cvr,
    -- SUM(price_usd) AS total_revenue,
    SUM(price_usd) / COUNT(DISTINCT order_id) AS revenue_per_order,
    SUM(price_usd) / COUNT(DISTINCT ws.website_session_id) AS revenue_per_session
FROM website_sessions ws
	LEFT JOIN orders o USING (website_session_id)
GROUP BY 1, 2
;

/*
11. I’d like to show how we’ve grown specific channels. Could you pull a quarterly view of orders from
Gsearch nonbrand, Bsearch nonbrand, brand search overall, organic search, and direct type-in?
*/

SELECT
	YEAR(ws.created_at) AS year,
    QUARTER(ws.created_at) AS qtr,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) AS gsearch_nonbrand_orders,
	COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) AS bsearch_nonbrand_orders,
	COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN order_id ELSE NULL END) AS brand_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN order_id ELSE NULL END) AS direct_type_in_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN order_id ELSE NULL END) AS organic_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source = 'socialbook' THEN order_id ELSE NULL END) AS social_orders
FROM website_sessions ws
	LEFT JOIN orders o USING (website_session_id)
GROUP BY 1, 2
;

/*
12. Next, let’s show the overall session-to-order conversion rate trends for those same channels, by quarter. 
Please also make a note of any periods where we made major improvements or optimizations.
*/

SELECT
	YEAR(ws.created_at) AS year,
    QUARTER(ws.created_at) AS qtr,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS gsearch_nonbrand_cvr,
	COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS bsearch_nonbrand_cvr,
	COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_search_cvr,
	COUNT(DISTINCT CASE WHEN utm_source = 'socialbook' THEN order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN utm_source = 'socialbook' THEN ws.website_session_id ELSE NULL END) AS social_cvr,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN ws.website_session_id ELSE NULL END) AS direct_cvr,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN ws.website_session_id ELSE NULL END) AS organic_search_cvr
    
FROM website_sessions ws
	LEFT JOIN orders o USING (website_session_id)
GROUP BY 1,2
;

/*
13. We’ve come a long way since the days of selling a single product. 
Let’s pull monthly trending for revenue and margin by product, along with total sales and revenue. 
Note anything you notice about seasonality.
*/

SELECT
	YEAR(created_at) AS year,
    MONTH(created_at) AS month,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd) - SUM(cogs_usd) AS total_margin,
    SUM(CASE WHEN product_id = 1 THEN price_usd ELSE 0 END) AS mr_fuzzy_revenue,
    SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd ELSE 0 END) AS mr_fuzzy_margin,
    SUM(CASE WHEN product_id = 2 THEN price_usd ELSE 0 END) AS love_bear_revenue,
    SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd ELSE 0 END) AS love_bear_margin,
    SUM(CASE WHEN product_id = 3 THEN price_usd ELSE 0 END) AS sugar_panda_revenue,
    SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd ELSE 0 END) AS sugar_panda_margin,
    SUM(CASE WHEN product_id = 4 THEN price_usd ELSE 0 END) AS mini_bear_revenue,
    SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd ELSE 0 END) AS mini_bear_margin
FROM order_items
GROUP BY 1, 2
;

/*
14. Let’s dive deeper into the impact of introducing new products. 
Please pull monthly sessions to the /products page, 
and show how the % of those sessions clicking through another page has changed over time, 
along with a view of how conversion from /products to placing an order has improved.
*/

CREATE TEMPORARY TABLE sessions_seeing_product_page
SELECT
	website_session_id,
    website_pageview_id,
    created_at AS saw_product_page_at
FROM website_pageviews
WHERE
	pageview_url = '/products'
;

SELECT
	YEAR(s.saw_product_page_at) AS year,
	MONTH(s.saw_product_page_at) AS month,
	COUNT(DISTINCT s.website_session_id) AS products_page_sessions,
	COUNT(DISTINCT wp.website_session_id) AS clicked_to_next_page,
    COUNT(DISTINCT wp.website_session_id) / COUNT(DISTINCT s.website_session_id) AS clickthrough_rate,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT s.website_session_id) AS product_to_order_cvr
FROM sessions_seeing_product_page s
	LEFT JOIN website_pageviews wp
		ON s.website_session_id = wp.website_session_id
		AND wp.website_pageview_id > s.website_pageview_id
	LEFT JOIN orders o
		ON s.website_session_id = o.website_session_id
GROUP BY 1, 2
;

/*
15. We made our 4th product available as a primary product on December 05, 2014 (it was previously only a cross-sell item).
Could you please pull sales data since then, and show how well each product cross-sells from one another?
*/

CREATE TEMPORARY TABLE primary_product_w_order
SELECT
	order_id,
    primary_product_id,
    created_at AS ordered_at
FROM orders
WHERE created_at >= '2014-12-05'
;

SELECT
		primary_product_id,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END) AS x_sold_product1,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END) AS x_sold_product2,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END) AS x_sold_product3,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END) AS x_sold_product4,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END) / COUNT(DISTINCT order_id) AS product1_cross_sell_cvr,
		COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END) / COUNT(DISTINCT order_id) AS product2_cross_sell_cvr,
		COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END) / COUNT(DISTINCT order_id) AS product3_cross_sell_cvr,
		COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END) / COUNT(DISTINCT order_id) AS product4_cross_sell_cvr
FROM
	(
		SELECT
			p.*,
			oi.product_id AS cross_sell_product_id
		FROM primary_product_w_order p
			LEFT JOIN order_items oi
				ON p.order_id = oi.order_id
				AND oi.is_primary_item = 0 -- cross sell only
	) AS t
GROUP BY 1
;