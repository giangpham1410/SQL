-- coi lai logic cau 18

select * from olympics_history;
select * from olympics_history_noc_regions;

-- 1. How many olympics games have been held?
SELECT COUNT (DISTINCT games) AS total_olympic_games
FROM olympics_history
;


-- 2. List down all Olympics games held so far.
SELECT
    DISTINCT year,
    season,
    city
FROM olympics_history
ORDER BY season, year
;


-- 3. Mention the total no of nations who participated in each olympics game?
SELECT
    games,
    COUNT (DISTINCT region) AS total_countries
FROM olympics_history
    JOIN olympics_history_noc_regions USING (noc)
GROUP BY games
;


-- 4. Which year saw the highest and lowest no of countries participating in olympics?
WITH t1 AS
    (
        SELECT
            games,
            COUNT (DISTINCT region) AS total_countries
        FROM olympics_history
            JOIN olympics_history_noc_regions USING (noc)
        GROUP BY games
    )
SELECT
    DISTINCT
    CONCAT(FIRST_VALUE(games) OVER h, ' - ', FIRST_VALUE(total_countries) OVER h) AS highest_no_of_countries,
    CONCAT(FIRST_VALUE(games) OVER l, ' - ', FIRST_VALUE(total_countries) OVER l) AS lowest_no_of_countries
FROM t1
WINDOW
    h AS (ORDER BY total_countries DESC),
    l AS (ORDER BY total_countries)
-- ORDER BY total_countries DESC
;


-- 5. Which nation has participated in all of the olympic games?
-- s1. Find total_olympic_games
-- s2. Each nation, how many times they participated in
-- s3. Compare 1 vs. 2
WITH
    t1 AS 
    (
        SELECT COUNT (DISTINCT games) AS total_olympic_games
        FROM olympics_history
    ),
    t2 AS
    (
        SELECT
            region,
            COUNT (DISTINCT games) AS no_of_games
        FROM olympics_history
            JOIN olympics_history_noc_regions USING (noc)
        GROUP BY region
        ORDER BY no_of_games DESC
    )
SELECT *
FROM t2
    JOIN t1 ON t1.total_olympic_games = t2.no_of_games
;


-- 6. Identify the sport which was played in all summer olympics.
-- s1. Find total number of games in summer season
-- s2. Find for each sport, how many games where they played in
-- s3. Compare s1 vs. s2
WITH
    t1 AS
    (
        SELECT
            -- season,
            COUNT (DISTINCT games) AS total_summer_games
        FROM olympics_history
        WHERE season = 'Summer'
        -- ORDER BY games
     ),
     t2 AS
     (
        SELECT
            sport,
            COUNT(DISTINCT games) AS no_of_games
        FROM olympics_history
        WHERE season = 'Summer'
        GROUP BY sport
        ORDER BY no_of_games DESC
     )
SELECT *
FROM t2
    JOIN t1 ON t1.total_summer_games = t2.no_of_games
;


-- 7. Which Sports were just played only once in the olympics?
-- s1. List down games, sport in the olympics
-- s2. For each sport: find no_of_games
-- s3. Fetch a list where no_of_games = 1
WITH
    t1 AS
    (
        SELECT
            DISTINCT games,
            sport
        FROM olympics_history
        ORDER BY games, sport
    ),
    t2 AS
    (
        SELECT
            sport,
            COUNT(DISTINCT games) AS no_of_games
        FROM t1
        GROUP BY sport
    )
SELECT
    t2.*,
    t1.games
FROM t2
    JOIN t1 USING (sport)
WHERE t2.no_of_games = 1
ORDER BY sport
;


-- 8. Fetch the total no of sports played in each olympic games.
SELECT
    DISTINCT games,
    COUNT(DISTINCT sport) AS no_of_sports
FROM olympics_history
GROUP BY games
ORDER BY no_of_sports DESC
;


-- 9. Fetch details of the oldest athletes to win a gold medal.
-- s1. Fetch a list who won a gold medal
-- s2. From s1, find oldest athletes
WITH t1 AS
    (
        SELECT *
        FROM olympics_history
        WHERE medal = 'Gold' AND age <> 'NA'
        ORDER BY age DESC
    ),
    t2 AS
    (
        SELECT
            *,
            DENSE_RANK() OVER (ORDER BY age DESC) AS age_rank
        FROM t1
    )
SELECT
    *
FROM t2
WHERE age_rank = 1
;


-- 10a. Find the Ratio of male and female athletes who participated in all olympic games.
-- s1. Fetch a list with id, sex
-- s2. Find total_athletes per sex
-- s2. Calculate ratio
WITH
    t1 AS
    (
        SELECT
            DISTINCT id,
            sex
        FROM olympics_history
    ),
    t2 AS
    (
        SELECT 
            COUNT(CASE WHEN sex = 'M' THEN 1 ELSE NULL END) AS male_athletes,
            COUNT(CASE WHEN sex = 'F' THEN 1 ELSE NULL END) AS female_athletes,
            COUNT(id) AS total_athletes,
            ROUND((COUNT(CASE WHEN sex = 'M' THEN 1 ELSE NULL END))::decimal /
                COUNT(CASE WHEN sex = 'F' THEN 1 ELSE NULL END), 1) AS ratio_cal
        FROM t1
    )
SELECT
    *,
    -- CONCAT('1 : ', ratio_cal) AS ratio,
    ROUND(male_athletes::decimal / total_athletes, 2) * 100 AS male_pct,
    ROUND(female_athletes::decimal / total_athletes, 2) * 100 AS male_pct
FROM t2
;
-- Result: 
-- The gender ratio in all olympic games is 300 males per 100 females.
-- The percentage of male athletes is 75% compare to 25% female.



-- 10b. Find the Ratio of male and female athletes who participated in each olympic games.
-- s1. Fetch a list: games, id, sex
-- s2. From s1, find total_athletes per sex
-- s3. Calculate ratio
WITH 
    t1 AS
    (
        SELECT
            DISTINCT games,
            id,
            sex
        FROM olympics_history
        ORDER BY id
    ),
    t2 AS
    (
        SELECT
            games,
            COUNT(CASE WHEN sex = 'M' THEN 1 ELSE NULL END) AS male_athletes,
            COUNT(CASE WHEN sex = 'F' THEN 1 ELSE NULL END) AS female_athletes,
            COUNT(id) AS total_athletes
        FROM t1
        GROUP BY 1
    )
SELECT
    *,
    -- male / NULLIF(female, 0) AS ratio,
    ROUND(male_athletes / NULLIF(female_athletes, 0)::decimal, 1) AS ratio,
    ROUND(male_athletes::decimal / total_athletes, 2) * 100 AS male_pct,
    ROUND(female_athletes::decimal / total_athletes, 2) * 100 AS female_pct
FROM t2
ORDER BY games
;
-- Result: 
-- 1900 Summer: 
-- a. The gender ratio in olympic games is 5221 males per 100 females.
-- b. The percentage of male athletes is 98% compared to 2% female.

-- 2016 Summer: 
-- a. The gender ratio in olympic games is 122 males per 100 females.
-- b. The percentage of male athletes is 55% compared to 45% female.

-- Summarize:
-- Over time, the ratio of male and female athletes
-- who participated in each olympic games is becoming more balanced



-- 11. Fetch the top 5 athletes who have won the most gold medals.
-- s1. Find athletes who have won gold medals 
-- s2. From s1, find the top 5 athletes who have the highest total gold medals
WITH
    t1 AS
        (
            SELECT
                name,
                team,
                COUNT(medal) AS total_gold_medals
            FROM olympics_history
            WHERE medal = 'Gold'
            GROUP BY name, team
            ORDER BY total_gold_medals DESC
        ),
    t2 AS
        (
            SELECT 
                *,
                DENSE_RANK() OVER (ORDER BY total_gold_medals DESC) AS medal_rank
            FROM t1
        )
SELECT *
FROM t2
WHERE medal_rank <= 5
;


-- 12. Fetch the top 5 athletes who have won the most medals (gold, silver and bronze).
-- s1. List down all athletes who have won medal, calculate total_medals
-- s2. Fetch top 5 athletes who have won the most medals
WITH 
    t1 AS
    (
        SELECT
            name,
            team,
            COUNT(medal) AS total_medals
        FROM olympics_history
        WHERE medal <> 'NA'
        GROUP BY 1,2
    ),
    t2 AS
    (
        SELECT
            *,
            DENSE_RANK() OVER (ORDER BY total_medals DESC) AS medal_rank
        FROM t1
    )
SELECT *
FROM t2
WHERE medal_rank <= 5
ORDER BY total_medals DESC
;


-- 13. Fetch the top 5 most successful countries in olympics. 
-- Success is defined by no of medals won.
-- s1. Fetch countries that won medals
-- s2. Fetch the top 5 countries which had the highest total_medals
WITH
    t1 AS
    (
        SELECT
            region,
            COUNT(medal) AS total_medals
        FROM olympics_history
            JOIN olympics_history_noc_regions USING (noc)
        WHERE medal <> 'NA'
        GROUP BY region
        ORDER BY total_medals DESC
    ),
    t2 AS
    (
        SELECT
            *,
            DENSE_RANK() OVER (ORDER BY total_medals DESC) AS medal_rank
        FROM t1
    )
SELECT *
FROM t2
WHERE medal_rank <= 5
;


-- 14. List down total gold, silver and bronze medals won by each country.
-- s1. List down medal = gold, silver, bronze
-- s2. From s1, find total medals, grouped by country, medal
WITH
    t1 AS
    (
        SELECT
            region,
            medal
        FROM olympics_history
            JOIN olympics_history_noc_regions USING (noc)
        WHERE medal <> 'NA'
    )
SELECT 
    region,
    COUNT(CASE WHEN medal = 'Gold' THEN 1 ELSE NULL END) AS gold_medals,
    COUNT(CASE WHEN medal = 'Silver' THEN 1 ELSE NULL END) AS silver_medals,
    COUNT(CASE WHEN medal = 'Bronze' THEN 1 ELSE NULL END) AS bronze_medals
FROM t1
GROUP BY region
ORDER BY gold_medals DESC
;


-- 15. List down total gold, silver and bronze medals won by each country 
-- corresponding to each olympic games.
-- s1. List down games, region and medals
-- s2. From s1, summarize medals by each games, each country
WITH
    t1 AS
    (
        SELECT
            games,
            region,
            medal
        FROM olympics_history
            JOIN olympics_history_noc_regions USING (noc)
        WHERE medal <> 'NA'
        ORDER BY 1,2,3
    )
SELECT
    games,
    region,
    COUNT(CASE WHEN medal = 'Gold' THEN 1 ELSE NULL END) AS gold_medals,
    COUNT(CASE WHEN medal = 'Silver' THEN 1 ELSE NULL END) AS silver_medals,
    COUNT(CASE WHEN medal = 'Bronze' THEN 1 ELSE NULL END) AS bronze_medals
FROM t1
GROUP BY 1, 2
;


-- 16. Identify which country won the most gold, most silver and most bronze medals 
-- in each olympic games.
-- s1. List down games, regions, medals
-- s2. Fetch total_medals per type for each games, each region
-- s3. Find max total_medals per type
WITH 
    t1 AS
    (
        SELECT
            games,
            region,
            medal
        FROM olympics_history
            JOIN olympics_history_noc_regions USING (noc)
        WHERE medal <> 'NA'
    ),
    t2 AS
    (
        SELECT
            games,
            region,
            COUNT(CASE WHEN medal = 'Gold' THEN 1 ELSE NULL END) AS gold,
            COUNT(CASE WHEN medal = 'Silver' THEN 1 ELSE NULL END) AS silver,
            COUNT(CASE WHEN medal = 'Bronze' THEN 1 ELSE NULL END) AS bronze
        FROM t1
        GROUP BY games, region
    )
SELECT
    DISTINCT games,
    CONCAT(FIRST_VALUE(region) OVER g, ' - ', FIRST_VALUE(gold) OVER g) AS max_gold,
    CONCAT(FIRST_VALUE(region) OVER s, ' - ', FIRST_VALUE(silver) OVER s) AS max_silver,
    CONCAT(FIRST_VALUE(region) OVER b, ' - ', FIRST_VALUE(bronze) OVER b) AS max_bronze
FROM t2
WINDOW
    g AS (PARTITION BY games ORDER BY gold DESC),
    s AS (PARTITION BY games ORDER BY silver DESC),
    b AS (PARTITION BY games ORDER BY bronze DESC)
ORDER BY games
;


-- 17. Identify which country won the most gold, most silver, 
-- most bronze medals and the most medals in each olympic games.
-- s1. List down countries which won gold, silver, bronze
-- s2. From s1, find highest_medals by type and total_medals
WITH
    t1 AS
    (
        SELECT
            games,
            region,
            medal
        FROM olympics_history
            JOIN olympics_history_noc_regions USING (noc)
        WHERE medal <> 'NA'
    ),
    t2 AS
    (
        SELECT
            games,
            region,
            COUNT(CASE WHEN medal = 'Gold' THEN 1 ELSE NULL END) AS gold_medals,
            COUNT(CASE WHEN medal = 'Silver' THEN 1 ELSE NULL END) AS silver_medals,
            COUNT(CASE WHEN medal = 'Bronze' THEN 1 ELSE NULL END) AS bronze_medals,
            COUNT(medal) AS total_medals
        FROM t1
        GROUP BY 1,2
    )
SELECT
    DISTINCT games,
    CONCAT(FIRST_VALUE(region) OVER g, ' - ', FIRST_VALUE(gold_medals) OVER g) AS max_gold,
    CONCAT(FIRST_VALUE(region) OVER s, ' - ', FIRST_VALUE(silver_medals) OVER s) AS max_silver,
    CONCAT(FIRST_VALUE(region) OVER b, ' - ', FIRST_VALUE(bronze_medals) OVER b) AS max_bronze,
    CONCAT(FIRST_VALUE(region) OVER tm, ' - ', FIRST_VALUE(total_medals) OVER tm) AS highest_total_medals
    
FROM t2
WINDOW
    g AS (PARTITION BY games ORDER BY gold_medals DESC),
    s AS (PARTITION BY games ORDER BY silver_medals DESC),
    b AS (PARTITION BY games ORDER BY bronze_medals DESC),
    tm AS (PARTITION BY games ORDER BY total_medals DESC)
ORDER BY games
;


-- 18. Which countries have never won gold medal but have won silver/bronze medals.
-- s1. List down region which won medals
WITH
    t1 AS
    (
        SELECT
            region,
            medal
        FROM olympics_history
            JOIN olympics_history_noc_regions USING (noc)
        -- WHERE medal <> 'NA'
    ),
    t2 AS
    (
        SELECT
            region,
            COUNT(CASE WHEN medal = 'Gold' THEN 1 ELSE NULL END) AS gold_medals,
            COUNT(CASE WHEN medal = 'Silver' THEN 1 ELSE NULL END) AS silver_medals,
            COUNT(CASE WHEN medal = 'Bronze' THEN 1 ELSE NULL END) AS bronze_medals
        FROM t1
        GROUP BY 1
        ORDER BY 1
    )
SELECT *
FROM t2
WHERE gold_medals = 0 AND (silver_medals >= 0 OR bronze_medals >= 0)
;


-- 19. In which Sport/event, India has won highest medals.
SELECT
    sport,
    COUNT(medal) AS total_medals
FROM olympics_history
    JOIN olympics_history_noc_regions USING (noc)
WHERE region = 'India' AND medal <> 'NA'
GROUP BY sport
ORDER BY total_medals DESC
LIMIT 1
;


-- 20. Break down all olympic games where india won medal for Hockey 
-- and how many medals in each olympic games.
-- s1. Fetch a list of which India won medals in Hockey
-- s2. From s1, find total_medals per type
WITH
    t1 AS
    (
        SELECT
            region,
            sport,
            games,
            medal
        FROM olympics_history
            JOIN olympics_history_noc_regions USING (noc)
        WHERE region = 'India' AND sport = 'Hockey' AND medal <> 'NA'
    )
SELECT
    region,
    sport,
    games,
    COUNT(CASE WHEN medal = 'Gold' THEN 1 ELSE NULL END) AS gold_medals,
    COUNT(CASE WHEN medal = 'Silver' THEN 1 ELSE NULL END) AS silver_medals,
    COUNT(CASE WHEN medal = 'Bronze' THEN 1 ELSE NULL END) AS bronze_medals,
    COUNT(medal) AS total_medals
FROM t1
GROUP BY region, sport, games
ORDER BY games
;