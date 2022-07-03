USE mavenfuzzyfactory;

-- 1. Finding top traffic soure: breakdown by UTM source, campaign and referring domain
SELECT
	utm_source,
    utm_campaign,
    http_referer,
    COUNT(website_session_id) AS number_of_sessions
FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY
	utm_source,
    utm_campaign,
    http_referer
ORDER BY
	number_of_sessions DESC;
    
-- 2. Finding traffic conversion rate: Calculate CVR from session to order (CVR >= 4%)
SELECT
	COUNT(ws.website_session_id) AS number_of_sessions,
    COUNT(o.order_id) AS number_of_orders,
	COUNT(o.order_id) / COUNT(ws.website_session_id) AS session_to_order_cvr
FROM website_sessions ws
	LEFT JOIN orders o USING (website_session_id)
WHERE ws.created_at < '2012-04-14' 
	AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand';
    
-- 3. Find orders with one item and two items,, with order_id from 31000 to 32000
SELECT
	primary_product_id,
    COUNT( CASE WHEN items_purchased = 1 THEN order_id ELSE NULL END ) AS orders_w_1_item,
    COUNT( CASE WHEN items_purchased = 2 THEN order_id ELSE NULL END ) AS orders_w_2_items,
    COUNT( order_id) AS number_of_orders
FROM orders
WHERE order_id BETWEEN 31000 AND 32000
GROUP BY
	primary_product_id;

/* 
4. Can you pull gsearch nonbrand trended session volume, by week, 
to see if the bid changes have caused volume to drop at all?
*/

SELECT
	MIN(DATE(DATE_ADD(created_at, INTERVAL(-WEEKDAY(created_at)) DAY))) AS week_start,
	COUNT( website_session_id ) AS number_of_sessions
FROM website_sessions
WHERE
	utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
    AND created_at < '2012-05-10'
 GROUP BY
    WEEK(created_at);

-- 5. Could you pull conversion rates from session to order, by device type?
SELECT
	device_type,
    COUNT(DISTINCT ws.website_session_id) AS number_of_sessions,
	COUNT(DISTINCT order_id) AS number_of_orders,
	COUNT(order_id) / COUNT(ws.website_session_id) * 100 AS session_to_order_cvr
FROM website_sessions ws
	LEFT JOIN orders USING (website_session_id)
WHERE
	utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
    AND ws.created_at < '2012-05-11'
GROUP BY
	device_type
;

/*
6. Could you pull weekly trends for both desktop and mobile so we can see the impact on volume?
You can use 2012-04-15 until the bid change as a baseline.
*/

SELECT
	MIN(DATE(DATE_ADD(created_at, INTERVAL(-WEEKDAY(created_at)) DAY))) AS week_start,
    COUNT(CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions
FROM website_sessions
WHERE
	created_at < '2012-06-09' AND created_at > '2012-04-15'
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY
	-- YEAR(created_at),
	WEEK(created_at)
;

/*
7. Could you help me get my head around the site 
by pulling the most-viewed website pages, ranked by session volume?
*/

SELECT
	pageview_url,
    COUNT(website_pageview_id) AS number_of_pageviews
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY
	pageview_url
ORDER BY
	number_of_pageviews DESC
;

/*
8. Would you be able to pull a list of the top entry pages? I want to confirm where our users are hitting the site.
If you could pull all entry pages and rank them on entry volume, that would be great.
*/

SELECT
	wp.pageview_url,
    COUNT(DISTINCT first_pageview.website_session_id) AS number_of_sessions
FROM
	(
    SELECT
		website_session_id,
		MIN(website_pageview_id) AS min_pageview_id
	FROM website_pageviews
	WHERE created_at < '2012-06-12'
	GROUP BY 1
    ) AS first_pageview
	LEFT JOIN website_pageviews wp
		ON first_pageview.min_pageview_id = wp.website_pageview_id
GROUP BY 1
;

/*
9. Can you pull bounce rates for traffic landing on the homepage?
I would like to see three numbers...Sessions, Bounced Sessions, 
and % of Sessions which Bounced (aka “Bounce Rate”).
*/

-- Step 1: Find first_pageview_id
-- Step 2: Find url
-- Step 3: Create bounced_session_only: Count pageview each session
-- Step 4: Count total_sessions and bounced_sessions -> calculate bounce_rate

-- Step 1: Find first_pageview_id
CREATE TEMPORARY TABLE first_pageview_id
SELECT
	website_session_id,
    MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY
	website_session_id;
    
-- Step 2: Find URL for min_pageview_id
CREATE TEMPORARY TABLE landing_page_url
SELECT
	f.website_session_id,
    wp.pageview_url
FROM first_pageview_id f
	LEFT JOIN website_pageviews wp
		ON f.min_pageview_id = wp.website_pageview_id
WHERE pageview_url = '/home'
;

-- Step 3: Create bounced_session_only: Count pageview each session
CREATE TEMPORARY TABLE bounced_session_only
SELECT
	l.website_session_id,
    l.pageview_url,
    COUNT(wp.website_pageview_id) AS count_pageview_id
FROM landing_page_url l
	LEFT JOIN website_pageviews wp USING(website_session_id)
GROUP BY
	l.website_session_id,
    l.pageview_url
HAVING count_pageview_id = 1
;

-- Step 4: Count total_sessions and bounced_sessions -> calculate bounce_rate
SELECT
	l.website_session_id,
    b.website_session_id AS bounced_session_id
FROM landing_page_url l
	LEFT JOIN bounced_session_only b USING (website_session_id)
ORDER BY
	l.website_session_id
;

SELECT
	COUNT(l.website_session_id) AS total_sessions,
    COUNT(b.website_session_id) AS bounced_session,
    COUNT(b.website_session_id) / COUNT(l.website_session_id) AS bounce_rate
FROM landing_page_url l
	LEFT JOIN bounced_session_only b USING (website_session_id);
    
/*
10. Based on your bounce rate analysis, we ran a new custom landing page (/lander-1)
in a 50/50 test against the homepage (/home) for our gsearch nonbrand traffic.
Can you pull bounce rates for the two groups so we can evaluate the new page? 
Make sure to just look at the time period where /lander-1 was getting traffic, so that it is a fair comparison.
*/

-- Step 0: Find out when /lander-1 launch
-- Step 1: Find first_pageview_id
-- Step 2: Find landing_page_url
-- Step 3: Create bounced_session_only
-- Step 4: Summarizing total_sessions, bounced_sessions, bounce_rate

-- Step 0: Find out when /lander-1 launch
SELECT
    MIN(created_at) AS first_created_at,
    MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE
	pageview_url = '/lander-1'
    AND created_at IS NOT NULL;
    
-- first_created_at: 2012-06-19 00:35:54
-- first_pageview_id: 23504

-- Step 1: Find first_pageview_id for each session
CREATE TEMPORARY TABLE first_pageview_id
SELECT
	wp.website_session_id,
    MIN(wp.website_pageview_id) AS first_pageview_id
FROM website_pageviews wp
	JOIN website_sessions ws USING (website_session_id)
WHERE 
	wp.website_pageview_id >= 23504
	AND ws.utm_source = 'gsearch'
    AND ws.utm_campaign = 'nonbrand'
    AND ws.created_at < '2012-07-28'
GROUP BY
	wp.website_session_id
;

-- Step 2: Find landing_page_url for each session
CREATE TEMPORARY TABLE landing_page_url
SELECT
	f.website_session_id,
    w.pageview_url
FROM first_pageview_id f
	LEFT JOIN website_pageviews w
		ON f.first_pageview_id = w.website_pageview_id
WHERE w.pageview_url IN ('/home', '/lander-1');

-- Step 3: Create bounced_session_only for each session
CREATE TEMPORARY TABLE bounced_session_only
SELECT
	l.website_session_id,
    l.pageview_url,
	COUNT(w.website_pageview_id) AS count_pageview_id
FROM landing_page_url l
	LEFT JOIN website_pageviews w USING (website_session_id)
GROUP BY
	l.website_session_id,
    l.pageview_url
HAVING
	count_pageview_id = 1
;

-- Step 4: Summarizing total_sessions, bounced_sessions, bounce_rate
SELECT
	l.pageview_url,
	COUNT(l.website_session_id) AS total_sessions,
    COUNT(b.website_session_id) AS bounced_sessions,
    COUNT(b.website_session_id) / COUNT(l.website_session_id) AS bounced_rate
FROM landing_page_url l
	LEFT JOIN bounced_session_only b USING (website_session_id)
GROUP BY
	l.pageview_url;

/*
11. Could you pull the volume of paid search nonbrand traffic landing on /home and /lander-1, 
trended weekly since June 1st? I want to confirm the traffic is all routed correctly.
Could you pull the volume of paid search nonbrand traffic landing on /home and /lander-1, trended weekly since June 1st? 
I want to confirm the traffic is all routed correctly.
Could you also pull our overall paid search bounce rate trended weekly?
I want to make sure the lander change has improved the overall picture.
*/

-- Step 1: Find first pageview id and count pageview id for each session
-- Step 2: Find landing page url and created at for each session
-- Step 3: Summarizing by week: bounce_rate, home_sessions, lander_1_sessions

-- Step 1: Find first pageview id and count pageview id for each session
CREATE TEMPORARY TABLE session_w_min_pv_id_and_count_pv
SELECT
	ws.website_session_id,
    MIN(wp.website_pageview_id) AS first_pageview_id,
    COUNT(wp.website_pageview_id) AS count_pageview_id
FROM website_sessions ws
	LEFT JOIN website_pageviews wp USING (website_session_id)
WHERE
	ws.created_at > '2012-06-01'
    AND ws.created_at < '2012-08-31'
    AND ws.utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY
	ws.website_session_id
ORDER BY
	ws.website_session_id;
    
-- Step 2: Find landing page url and created at for each session
CREATE TEMPORARY TABLE session_w_landing_page_and_created_at
SELECT
	s.website_session_id,
    s.first_pageview_id,
    s.count_pageview_id,
    wp.pageview_url,
    wp.created_at
FROM session_w_min_pv_id_and_count_pv s
	LEFT JOIN website_pageviews wp
		ON s.first_pageview_id = wp.website_pageview_id
;

-- Step 3: Summarizing by week: bounce_rate, home_sessions, lander_1_sessions
SELECT
	MIN(DATE(DATE_ADD(created_at, INTERVAL(-WEEKDAY(created_at)) DAY))) AS week_start_date,
    COUNT(website_session_id) AS total_sessions,
    COUNT(CASE WHEN count_pageview_id = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
    COUNT(CASE WHEN count_pageview_id = 1 THEN website_session_id ELSE NULL END) / COUNT(website_session_id) AS bounce_rate,
    COUNT(CASE WHEN pageview_url = '/home' THEN website_session_id ELSE NULL END) AS home_sessions,
    COUNT(CASE WHEN pageview_url = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_sessions
FROM session_w_landing_page_and_created_at
GROUP BY
	WEEK(created_at)
;

/*
12. I’d like to understand where we lose our gsearch visitors between the new /lander-1 page and placing an order. 
Can you build us a full conversion funnel, analyzing how many customers make it to each step?
Start with /lander-1 and build the funnel all the way to our thank you page. 
Please use data since August 5th.
*/

CREATE TEMPORARY TABLE session_level
SELECT
	website_session_id,
    MAX(products_page) AS product_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM 
	(
    SELECT
		ws.website_session_id,
		wp.pageview_url,
		-- wp.created_at AS pageview_created_at,
		CASE WHEN wp.pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
		CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
		CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
		CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
		CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
		CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
	FROM website_sessions ws
		LEFT JOIN website_pageviews wp USING (website_session_id)
	WHERE
		ws.created_at > '2012-08-05'
		AND ws.created_at < '2012-09-05'
		AND ws.utm_source = 'gsearch'
		AND ws.utm_campaign = 'nonbrand'
	ORDER BY
		ws.website_session_id,
		wp.pageview_url
	) AS pageview_session
GROUP BY
	website_session_id
;

SELECT
	COUNT(DISTINCT website_session_id) AS total_sessions,
    COUNT(CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_product,
    COUNT(CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_level
;

SELECT
    COUNT(CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) 
		/ COUNT(DISTINCT website_session_id) AS clicked_to_product_rate,
    COUNT(CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS clicked_to_mrfuzzy_rate,
    COUNT(CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS clicked_to_cart_rate,
    COUNT(CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS clicked_to_shipping_rate,
    COUNT(CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS clicked_to_billing_rate,
    COUNT(CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)
		/ COUNT(CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS clicked_to_thankyou_rate
FROM session_level
;

/*
13. We tested an updated billing page based on your funnel analysis. 
Can you take a look and see whether /billing-2 is doing any better than the original /billing page?
We’re wondering what % of sessions on those pages end up placing an order. 
FYI – we ran this test for all traffic, not just for our search visitors.
*/

-- finding first time /billing-2 was seen: 
SELECT
	MIN(created_at), -- result: 53550
    MIN(website_pageview_id) -- result: 2012-09-10
FROM website_pageviews
WHERE
	pageview_url = '/billing-2'
;

SELECT 
	pageview_url,
    COUNT(website_session_id) AS total_sessions,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT order_id) / COUNT(website_session_id) AS cvr
FROM website_pageviews wp
	LEFT JOIN orders o USING (website_session_id)
WHERE
	website_pageview_id >= 53550
    AND wp.created_at < '2012-11-10'
	AND pageview_url IN ('/billing-2', '/billing')
GROUP BY
	pageview_url
;