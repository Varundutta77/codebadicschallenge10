-- Q1 Top 10 Batsman based on past 3 years total runs scored

SELECT
		batsmanName AS Batsman,
		SUM(runs) as Total_Run
FROM 
		IPL..fact_bating_summary fs
JOIN
		IPL..dim_match_summary dm ON dm.match_id = fs.match_id
WHERE 
		YEAR(dm.matchDate) >=2021 AND YEAR(dm.matchDate) <=2023
GROUP BY
		batsmanName
ORDER BY 
		Total_Run DESC OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Q2 Top 10 Batsman based on past 3 years batting average (min 60 balls faced in each season)

SELECT
		batsmanName,
		ROUND(CAST(SUM(runs)AS FLOAT)/COUNT(CASE WHEN out_not_out = 'Out' THEN 1 END),2) as batting_avg
FROM	
		IPL..fact_bating_summary fs
JOIN
		ipl..dim_match_summary dm ON dm.match_id = fs.match_id
WHERE 
		YEAR(dm.matchDate) >=2021 AND YEAR(dm.matchDate) <=2023
GROUP BY
		batsmanName
HAVING 
		Sum(balls) >60 AND COUNT(DISTINCT YEAR(dm.matchDate))=3
ORDER BY
		batting_avg DESC OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY ;

-- Q3 Top 10 batsmen based on past 3 years strike rate (min 60 balls faced in each season)

SELECT
		batsmanName,
		ROUND(CAST(SUM(runs)AS FLOAT)/SUM(balls),2)*100 as batting_avg
FROM	
		IPL..fact_bating_summary fs
JOIN
		ipl..dim_match_summary dm ON dm.match_id = fs.match_id
WHERE 
		YEAR(dm.matchDate) >=2021 AND YEAR(dm.matchDate) <=2023
GROUP BY
		batsmanName
HAVING 
		Sum(balls) >60 AND COUNT(DISTINCT YEAR(dm.matchDate))=3
ORDER BY
		batting_avg DESC OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY

-- Q4 Top 10 bowlers based on past 3 years total wickets taken.

SELECT 
		bowlerName AS bowler,
		SUM(wickets) AS total_wickets
FROM
		IPL..fact_bowling_summary bs
JOIN 
		IPL..dim_match_summary dm ON dm.match_id = bs.match_id
WHERE 
		YEAR(dm.matchDate) >=2021 AND YEAR(dm.matchDate) <=2023
GROUP BY
		bowlerName
ORDER BY 
		total_wickets DESC OFFSET 0 ROWS FETCH FIRST 10 ROWS ONLY

-- Q5 Top 10 bowlers based on past 3 years bowling average. (min 60 balls bowled in each season)

SELECT
		bowlerName AS bowler,
		ROUND(CAST(SUM(runs)AS FLOAT)/SUM(wickets),2) as bowling_avg
FROM	
		IPL..fact_bowling_summary bs
JOIN
		ipl..dim_match_summary dm ON dm.match_id = bs.match_id
WHERE 
		YEAR(dm.matchDate) >=2021 AND YEAR(dm.matchDate) <=2023
GROUP BY
		bowlerName
HAVING 
		SUM(overs*6) >60 AND COUNT(DISTINCT YEAR(dm.matchDate))=3
ORDER BY
		bowling_avg ASC OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY 

-- Q6 Top 10 bowlers based on past 3 years economy rate. (min 60 balls bowled in each season)

SELECT
    bowlerName AS bowler,
    ROUND(CAST(SUM(runs) AS FLOAT) / SUM(CASE WHEN FLOOR(overs) = overs THEN FLOOR(overs) * 6 ELSE FLOOR(overs) * 6 + CAST((overs - FLOOR(overs)) * 10 AS INT) END), 2)*6 AS bowling_avg
FROM    
    IPL..fact_bowling_summary bs
JOIN
    ipl..dim_match_summary dm ON dm.match_id = bs.match_id
WHERE 
    YEAR(dm.matchDate) >= 2021 AND YEAR(dm.matchDate) <= 2023
GROUP BY
    bowlerName
HAVING 
    SUM(CASE WHEN FLOOR(overs) = overs THEN FLOOR(overs) * 6 ELSE FLOOR(overs) * 6 + CAST((overs - FLOOR(overs)) * 10 AS INT)END) >= 60 
    AND COUNT(DISTINCT YEAR(dm.matchDate)) = 3
ORDER BY
    bowling_avg ASC OFFSET 0 ROWS FETCH FIRST 10 ROWS ONLY;

-- Q7 Top 5 batsmen based on past 3 years boundary % (fours and sixes).
SELECT
		batsmanName,
		ROUND(CAST(SUM(runs)AS FLOAT)/NULLIF(SUM(_4s*4 + _6s*6),0),2) AS boundary_runs
FROM
		IPL..fact_bating_summary bs
JOIN
		IPL..dim_match_summary dm ON dm.match_id = bs.match_id
WHERE
		YEAR(dm.matchDate) >=2021 AND YEAR(dm.matchDate) <=2023
GROUP BY
		batsmanName	
ORDER BY
		boundary_runs DESC OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY

-- Q8 Top 5 bowlers based on past 3 years dot ball %.
SELECT
    bowlerName,
    ROUND(
        (SUM(_0s) / SUM(CASE 
            WHEN FLOOR(overs) = overs THEN FLOOR(overs) * 6 
            ELSE FLOOR(overs) * 6 + CAST((overs - FLOOR(overs)) * 10 AS INT) 
        END)) * 100, 2
    ) AS dot_ball
FROM
    IPL..fact_bowling_summary fb
JOIN
    IPL..dim_match_summary dm ON dm.match_id = fb.match_id
WHERE
    YEAR(dm.matchDate) >= 2021 AND YEAR(dm.matchDate) <= 2023
GROUP BY
    bowlerName
ORDER BY
    dot_ball DESC;
	
-- Q9 Top 4 teams based on past 3 years winning %.
SELECT 
    team1 AS team,
    ROUND(CAST(COUNT(CASE WHEN winner = team1 THEN 1 END) AS FLOAT) / COUNT(match_id),2) * 100 AS winning_percentage
FROM 
    IPL..dim_match_summary dm
WHERE 
    YEAR(dm.matchDate) BETWEEN 2021 AND 2023
GROUP BY 
    team1
UNION
SELECT 
    team2 AS team,
    ROUND(CAST(COUNT(CASE WHEN winner = team2 THEN 1 END) AS FLOAT) / COUNT(match_id),2) * 100 AS winning_percentage
FROM 
    IPL..dim_match_summary dm
WHERE 
    YEAR(dm.matchDate) BETWEEN 2021 AND 2023
GROUP BY 
    team2
ORDER BY 
    winning_percentage DESC OFFSET 0 ROWS FETCH FIRST 4 ROWS ONLY;

-- Q10 Top 2 teams with the highest number of wins achieved by chasing targets over the past 3 years.
SELECT
    team AS team_name,
    COUNT(*) AS total_matches,
    FORMAT(ROUND(SUM(CASE WHEN margin LIKE '%wickets%' OR margin LIKE '%wicket%' THEN 1 ELSE 0 END) * 1.0 / COUNT(match_id) * 100,2),'0.##') AS chase_win_rate
FROM (
    SELECT team1 AS team, 
		match_id, 
		margin
    FROM 
		IPL..dim_match_summary
    WHERE 
		YEAR(matchDate) BETWEEN 2021 AND 2023
    
    UNION ALL
    
    SELECT 
		team2 AS team, 
		match_id, 
		margin
    FROM 
		IPL..dim_match_summary
    WHERE 
		YEAR(matchDate) BETWEEN 2021 AND 2023
) AS combined_teams
GROUP BY team
ORDER BY chase_win_rate DESC OFFSET 0 ROWS FETCH FIRST 2 ROWS ONLY;
