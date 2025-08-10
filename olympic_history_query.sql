/*1. How many olympics games have been held? */
SELECT COUNT(DISTINCT games)  FROM olympics_history

/* 2. List down all Olympics games held so far. */
SELECT DISTINCT year,season,city FROM olympics_history
ORDER BY year


/* 3. Mention the total no of nations who participated in each olympics game? */
SELECT games,COUNT(DISTINCT region)
FROM olympics_history oh
JOIN noc_regions nr ON nr.noc=oh.noc
GROUP BY 1

/* 4. Which year saw the highest and lowest no of countries participating in olympics */
WITH cte AS(
	SELECT games,COUNT(DISTINCT region) AS count_country
FROM olympics_history oh
JOIN noc_regions nr ON nr.noc=oh.noc
GROUP BY 1)

SELECT DISTINCT
CONCAT(FIRST_VALUE(games) OVER(ORDER BY count_country DESC),'-',
FIRST_VALUE(count_country) OVER(ORDER BY count_country DESC)) AS highest_country,
CONCAT(FIRST_VALUE(games) OVER(ORDER BY count_country),'-',
FIRST_VALUE(count_country) OVER(ORDER BY count_country)) AS lowest_country
FROM cte

/* 5. Which nation has participated in all of the olympic games */
SELECT region AS COUNTRY,COUNT(DISTINCT games) AS total_participated_games
FROM oh
JOIN nr ON nr.noc=oh.noc
GROUP BY 1
HAVING COUNT(DISTINCT games)=(SELECT COUNT(DISTINCT games) FROM oh)

/* 6. Identify the sport which was played in all summer olympics. */
SELECT sport,COUNT(DISTINCT games) FROM oh
GROUP BY sport
HAVING COUNT(DISTINCT games)=(SELECT COUNT(DISTINCT games) FROM oh
WHERE games ILIKE '%summer%')


/* 7. Which Sports were just played only once in the olympics. */
WITH cte AS(
SELECT DISTINCT games,sport FROM oh
),
cte2 AS (
SELECT sport,COUNT(games) AS no_of_games
	FROM cte
	GROUP BY 1
)
SELECT cte2.*,cte.games
FROM cte
JOIN cte2 ON cte.sport=cte2.sport
WHERE no_of_games=1
ORDER BY sport


/* 8. Fetch the total no of sports played in each olympic games. */
SELECT games,COUNT(DISTINCT sport)
FROM oh
GROUP BY 1
ORDER BY 2 DESC


/* 9. Fetch oldest athletes to win a gold medal */
WITH cte AS(
	SELECT name, CAST(CASE WHEN age='NA' THEN '0' ELSE age END AS int) AS age
,team,games,city,sport, event, medal
FROM oh
WHERE medal='Gold')
SELECT * FROM cte
WHERE age=(SELECT MAX(age) FROM cte)


/* 10. Find the Ratio of male and female athletes participated in all olympic games. */
WITH t1 AS(
SELECT SUM(CASE WHEN sex='M' THEN 1 ELSE 0 END) AS male,
SUM(CASE WHEN sex='F' THEN 1 ELSE 0 END) AS female
FROM oh)
SELECT CONCAT('1 : ',ROUND((male/female::decimal),2))
FROM t1


/* 11. Fetch the top 5 athletes who have won the most gold medals. */
WITH t1 AS(
	SELECT name,team,COUNT(1) mc
FROM oh
WHERE medal='Gold'
GROUP BY 1,2
ORDER BY 3 DESC),
t2 AS(SELECT *,DENSE_RANK() OVER(ORDER BY mc DESC ) rn
	  FROM t1)
SELECT name,team,mc AS gold_medal_count FROM t2
WHERE rn<=5


/* 12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze). */
WITH t1 AS(
	SELECT name,team,COUNT(1) mc
FROM oh
WHERE medal<>'NA'
GROUP BY 1,2
ORDER BY 3 DESC),
t2 AS(SELECT *,DENSE_RANK() OVER(ORDER BY mc DESC ) rn
	  FROM t1)
SELECT name,team,mc AS gold_medal_count FROM t2
WHERE rn<=5


/* 13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won. */
ITH t1 AS(
	SELECT region,COUNT(1) medal_count
FROM oh
JOIN nr ON nr.noc=oh.noc
WHERE medal<>'NA'
GROUP BY 1
ORDER BY 2 DESC),
t2 AS(SELECT *,DENSE_RANK() OVER(ORDER BY medal_count DESC ) rn
	  FROM t1)
SELECT * FROM t2
WHERE rn<=5


/* 14. List down total gold, silver and bronze medals won by each country. */
SELECT region,
SUM(CASE WHEN medal='Gold' THEN 1 ELSE 0 END) AS gold_medal,
SUM(CASE WHEN medal='Silver' THEN 1 ELSE 0 END) AS silver_medal,
SUM(CASE WHEN medal='Bronze' THEN 1 ELSE 0 END) AS bronze_medal
FROM oh
JOIN nr ON nr.noc=oh.noc
GROUP BY region
ORDER BY 2 DESC


/* 15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games. */
SELECT games,region,
SUM(CASE WHEN medal='Gold' THEN 1 ELSE 0 END) AS gold_medal,
SUM(CASE WHEN medal='Silver' THEN 1 ELSE 0 END) AS silver_medal,
SUM(CASE WHEN medal='Bronze' THEN 1 ELSE 0 END) AS bronze_medal
FROM oh
JOIN nr ON nr.noc=oh.noc
GROUP BY region,games
ORDER BY 1 


/* 16. Identify which country won the most gold, most silver and most bronze medals in each olympic games. */
WITH t1 AS(
	SELECT games,region,
SUM(CASE WHEN medal='Gold' THEN 1 ELSE 0 END) AS Gold,
SUM(CASE WHEN medal='Silver' THEN 1 ELSE 0 END) AS silver,
SUM(CASE WHEN medal='Bronze' THEN 1 ELSE 0 END) AS Bronze
FROM oh
JOIN nr ON oh.noc=nr.noc
GROUP by 1,2)

SELECT DISTINCT games,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY gold DESC),'-',
	  FIRST_VALUE(gold) OVER(PARTITION BY games ORDER BY gold DESC)) AS max_gold,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY silver DESC),'-',
	  FIRST_VALUE(gold) OVER(PARTITION BY games ORDER BY silver DESC)) AS max_silver,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY bronze DESC),'-',
	  FIRST_VALUE(gold) OVER(PARTITION BY games ORDER BY bronze DESC)) AS max_bronze
	  FROM t1
	  ORDER BY 1


/* 17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games. */
WITH t1 AS(
	SELECT games,region,
SUM(CASE WHEN medal='Gold' THEN 1 ELSE 0 END) AS Gold,
SUM(CASE WHEN medal='Silver' THEN 1 ELSE 0 END) AS silver,
SUM(CASE WHEN medal='Bronze' THEN 1 ELSE 0 END) AS Bronze,
SUM(CASE WHEN medal<>'NA' THEN 1 ELSE 0 END) AS medal
FROM oh
JOIN nr ON oh.noc=nr.noc
GROUP by 1,2)

SELECT DISTINCT games,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY gold DESC),'-',
	  FIRST_VALUE(gold) OVER(PARTITION BY games ORDER BY gold DESC)) AS max_gold,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY silver DESC),'-',
	  FIRST_VALUE(silver) OVER(PARTITION BY games ORDER BY silver DESC)) AS max_silver,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY bronze DESC),'-',
	  FIRST_VALUE(bronze) OVER(PARTITION BY games ORDER BY bronze DESC)) AS max_bronze,
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY medal DESC),'-',
	  FIRST_VALUE(medal) OVER(PARTITION BY games ORDER BY medal DESC)) AS max_medal
	  FROM t1
	  ORDER BY 1


/* 18. Which countries have never won gold medal but have won silver/bronze medals? */
WITH t1 AS(
	SELECT region,
SUM(CASE WHEN medal='Gold' THEN 1 ELSE 0 END) AS gold,
SUM(CASE WHEN medal='Silver' THEN 1 ELSE 0 END) AS silver,
SUM(CASE WHEN medal='Bronze' THEN 1 ELSE 0 END) AS bronze
FROM oh
JOIN nr ON nr.noc=oh.noc
GROUP BY 1)
SELECT * FROM t1
WHERE gold=0 AND(silver>0 OR bronze>0)


/* 19. In which Sport/event, India has won highest medals. */
WITH t1 AS(
	SELECT sport,
SUM(CASE WHEN medal<>'NA' THEN 1 ELSE 0 END) AS total_medal
FROM oh
JOIN nr ON nr.noc=oh.noc
WHERE region='India'
GROUP BY 1)
SELECT * FROM t1
WHERE total_medal=(SELECT MAX(total_medal) FROM t1)


/* 20. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games */
SELECT games,team,sport,
SUM(CASE WHEN medal<>'NA' THEN 1 ELSE 0 END) AS total_medal
FROM oh
WHERE team='India' AND sport='Hockey'
GROUP BY 1,2,3
ORDER BY 4 DESC









