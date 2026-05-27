
/*
============================================================
Football Project — End-to-End Descriptive SQL Analysis
Database: Microsoft SQL Server
Purpose:
  1) Create clean analysis views from the loaded relational tables
  2) Create simple summary tables for presentation/report
  3) Use descriptive statistics only: counts, percentages, means, SDs

How to run:
  - Open this file in SQL Server Management Studio / Azure Data Studio
  - Select the correct database: FootballProject
  - Run the whole script
  - The final SELECT statements will display all summary tables

Important:
  These are descriptive summaries, not formal statistical hypothesis tests.
============================================================
*/

---------------------------------------------------------
-- STEP 0. DROP OLD SUMMARY TABLES AND ANALYSIS VIEWS
----------------------------------------------------------

IF OBJECT_ID('dbo.Summary_00_DataQualityStatus', 'U') IS NOT NULL DROP TABLE dbo.Summary_00_DataQualityStatus;
IF OBJECT_ID('dbo.Summary_01_DatabaseOverview', 'U') IS NOT NULL DROP TABLE dbo.Summary_01_DatabaseOverview;
IF OBJECT_ID('dbo.Summary_02_MatchResults', 'U') IS NOT NULL DROP TABLE dbo.Summary_02_MatchResults;
IF OBJECT_ID('dbo.Summary_03_HomeAdvantageByDecade', 'U') IS NOT NULL DROP TABLE dbo.Summary_03_HomeAdvantageByDecade;
IF OBJECT_ID('dbo.Summary_04_GoalsByDecade', 'U') IS NOT NULL DROP TABLE dbo.Summary_04_GoalsByDecade;
IF OBJECT_ID('dbo.Summary_05_ScoreMarginDistribution', 'U') IS NOT NULL DROP TABLE dbo.Summary_05_ScoreMarginDistribution;
IF OBJECT_ID('dbo.Summary_06_GoalTiming', 'U') IS NOT NULL DROP TABLE dbo.Summary_06_GoalTiming;
IF OBJECT_ID('dbo.Summary_07_GoalType', 'U') IS NOT NULL DROP TABLE dbo.Summary_07_GoalType;
IF OBJECT_ID('dbo.Summary_08_ShootoutFirstShooter', 'U') IS NOT NULL DROP TABLE dbo.Summary_08_ShootoutFirstShooter;
IF OBJECT_ID('dbo.Summary_09_TeamPerformance', 'U') IS NOT NULL DROP TABLE dbo.Summary_09_TeamPerformance;
IF OBJECT_ID('dbo.Summary_10_TournamentScoring', 'U') IS NOT NULL DROP TABLE dbo.Summary_10_TournamentScoring;
IF OBJECT_ID('dbo.Summary_11_TopScorers', 'U') IS NOT NULL DROP TABLE dbo.Summary_11_TopScorers;
GO

IF OBJECT_ID('dbo.v_goalscorer_analysis', 'V') IS NOT NULL DROP VIEW dbo.v_goalscorer_analysis;
GO
IF OBJECT_ID('dbo.v_shootout_analysis', 'V') IS NOT NULL DROP VIEW dbo.v_shootout_analysis;
GO
IF OBJECT_ID('dbo.v_match_analysis', 'V') IS NOT NULL DROP VIEW dbo.v_match_analysis;
GO


-----------------------------------------------------------
-- STEP 1. CREATE ANALYSIS VIEW: MATCH LEVEL
------------------------------------------------------------

CREATE VIEW dbo.v_match_analysis AS
SELECT
    m.MatchID,
    m.MatchDate,
    YEAR(m.MatchDate) AS MatchYear,
    (YEAR(m.MatchDate) / 10) * 10 AS MatchDecade,

    m.HomeTeamID,
    ht.TeamName AS HomeTeam,
    m.AwayTeamID,
    at.TeamName AS AwayTeam,

    m.HomeScore,
    m.AwayScore,
    (m.HomeScore + m.AwayScore) AS TotalGoals,
    ABS(m.HomeScore - m.AwayScore) AS GoalDifference,

    CASE
        WHEN m.HomeScore > m.AwayScore THEN 'Home win'
        WHEN m.HomeScore < m.AwayScore THEN 'Away win'
        ELSE 'Draw'
    END AS MatchResult,

    CASE
        WHEN m.HomeScore > m.AwayScore THEN m.HomeTeamID
        WHEN m.HomeScore < m.AwayScore THEN m.AwayTeamID
        ELSE NULL
    END AS WinnerTeamID,

    CASE
        WHEN m.HomeScore > m.AwayScore THEN m.AwayTeamID
        WHEN m.HomeScore < m.AwayScore THEN m.HomeTeamID
        ELSE NULL
    END AS LoserTeamID,

    t.TournamentName,
    l.City,
    l.Country,
    m.IsNeutral
FROM dbo.Fact_match m
INNER JOIN dbo.Team ht
    ON m.HomeTeamID = ht.TeamID
INNER JOIN dbo.Team at
    ON m.AwayTeamID = at.TeamID
LEFT JOIN dbo.Tournament t
    ON m.TournamentID = t.TournamentID
LEFT JOIN dbo.Location l
    ON m.LocationID = l.LocationID;
GO


---------------------------------------------------------
-- STEP 2. CREATE ANALYSIS VIEW: SHOOTOUT LEVEL
-- Deduplication is included defensively.
-----------------------------------------------------------

CREATE VIEW dbo.v_shootout_analysis AS
WITH shootout_dedup AS (
    SELECT
        s.MatchID,
        s.WinnerTeamID,
        s.FirstShooterTeamID,
        ROW_NUMBER() OVER (
            PARTITION BY s.MatchID, s.WinnerTeamID, ISNULL(s.FirstShooterTeamID, -1)
            ORDER BY s.MatchID, s.WinnerTeamID, ISNULL(s.FirstShooterTeamID, -1)
        ) AS rn
    FROM dbo.Fact_shootout s
)
SELECT
    s.MatchID,
    m.MatchDate,
    m.MatchYear,
    m.MatchDecade,
    m.HomeTeamID,
    m.HomeTeam,
    m.AwayTeamID,
    m.AwayTeam,

    s.WinnerTeamID,
    wt.TeamName AS WinnerTeam,

    s.FirstShooterTeamID,
    fst.TeamName AS FirstShooterTeam,

    CASE
        WHEN s.FirstShooterTeamID IS NULL THEN 'Unknown first shooter'
        WHEN s.FirstShooterTeamID = s.WinnerTeamID THEN 'First shooter won'
        ELSE 'First shooter lost'
    END AS FirstShooterResult,

    CASE
        WHEN s.FirstShooterTeamID IS NULL THEN NULL
        WHEN s.FirstShooterTeamID = s.WinnerTeamID THEN 1
        ELSE 0
    END AS FirstShooterWon,

    m.TournamentName,
    m.City,
    m.Country,
    m.IsNeutral
FROM shootout_dedup s
INNER JOIN dbo.v_match_analysis m
    ON s.MatchID = m.MatchID
INNER JOIN dbo.Team wt
    ON s.WinnerTeamID = wt.TeamID
LEFT JOIN dbo.Team fst
    ON s.FirstShooterTeamID = fst.TeamID
WHERE s.rn = 1;
GO


-----------------------------------------------------------
-- STEP 3. CREATE ANALYSIS VIEW: GOALSCORER LEVEL
-- Deduplication is included defensively.
----------------------------------------------------------

CREATE VIEW dbo.v_goalscorer_analysis AS
WITH goals_dedup AS (
    SELECT
        g.MatchID,
        g.ScoringTeamID,
        g.ScorerName,
        g.Minute,
        g.IsOwnGoal,
        g.IsPenalty,
        ROW_NUMBER() OVER (
            PARTITION BY
                g.MatchID,
                g.ScoringTeamID,
                g.ScorerName,
                ISNULL(g.Minute, -1),
                g.IsOwnGoal,
                g.IsPenalty
            ORDER BY
                g.MatchID,
                g.ScoringTeamID,
                g.ScorerName,
                ISNULL(g.Minute, -1),
                g.IsOwnGoal,
                g.IsPenalty
        ) AS rn
    FROM dbo.Fact_goalscorer g
)
SELECT
    g.MatchID,
    m.MatchDate,
    m.MatchYear,
    m.MatchDecade,
    m.HomeTeamID,
    m.HomeTeam,
    m.AwayTeamID,
    m.AwayTeam,
    m.HomeScore,
    m.AwayScore,
    m.TournamentName,
    m.City,
    m.Country,

    g.ScoringTeamID,
    st.TeamName AS ScoringTeam,
    g.ScorerName,
    g.Minute,

    CASE
        WHEN g.Minute IS NULL THEN 'Unknown minute'
        WHEN g.Minute <= 15 THEN '01-15'
        WHEN g.Minute <= 30 THEN '16-30'
        WHEN g.Minute <= 45 THEN '31-45'
        WHEN g.Minute <= 60 THEN '46-60'
        WHEN g.Minute <= 75 THEN '61-75'
        WHEN g.Minute <= 90 THEN '76-90'
        ELSE '90+'
    END AS MinutePeriod,

    CASE
        WHEN g.Minute IS NULL THEN 8
        WHEN g.Minute <= 15 THEN 1
        WHEN g.Minute <= 30 THEN 2
        WHEN g.Minute <= 45 THEN 3
        WHEN g.Minute <= 60 THEN 4
        WHEN g.Minute <= 75 THEN 5
        WHEN g.Minute <= 90 THEN 6
        ELSE 7
    END AS MinutePeriodOrder,

    g.IsOwnGoal,
    g.IsPenalty
FROM goals_dedup g
INNER JOIN dbo.v_match_analysis m
    ON g.MatchID = m.MatchID
INNER JOIN dbo.Team st
    ON g.ScoringTeamID = st.TeamID
WHERE g.rn = 1;
GO


-----------------------------------------------------------
-- STEP 4. CREATE SUMMARY TABLE 00: DATA QUALITY STATUS
-- Expected ProblemRows = 0 for all rows, except notes already accepted.
----------------------------------------------------------

SELECT *
INTO dbo.Summary_00_DataQualityStatus
FROM (
    SELECT
        'Fact_match impossible or missing values' AS CheckName,
        COUNT(*) AS ProblemRows
    FROM dbo.Fact_match
    WHERE HomeTeamID = AwayTeamID
       OR HomeScore < 0
       OR AwayScore < 0
       OR HomeScore IS NULL
       OR AwayScore IS NULL
       OR MatchDate IS NULL

    UNION ALL

    SELECT
        'Fact_shootout invalid match/team references' AS CheckName,
        COUNT(*) AS ProblemRows
    FROM dbo.Fact_shootout s
    LEFT JOIN dbo.Fact_match m
        ON s.MatchID = m.MatchID
    LEFT JOIN dbo.Team winner
        ON s.WinnerTeamID = winner.TeamID
    LEFT JOIN dbo.Team first_shooter
        ON s.FirstShooterTeamID = first_shooter.TeamID
    WHERE m.MatchID IS NULL
       OR winner.TeamID IS NULL
       OR (s.FirstShooterTeamID IS NOT NULL AND first_shooter.TeamID IS NULL)

    UNION ALL

    SELECT
        'Fact_goalscorer invalid match/team/scorer/minute values' AS CheckName,
        COUNT(*) AS ProblemRows
    FROM dbo.Fact_goalscorer g
    LEFT JOIN dbo.Fact_match m
        ON g.MatchID = m.MatchID
    LEFT JOIN dbo.Team scoring_team
        ON g.ScoringTeamID = scoring_team.TeamID
    WHERE m.MatchID IS NULL
       OR scoring_team.TeamID IS NULL
       OR g.ScorerName IS NULL
       OR LTRIM(RTRIM(g.ScorerName)) = ''
       OR (g.Minute IS NOT NULL AND (g.Minute < 1 OR g.Minute > 130))
       OR g.ScoringTeamID NOT IN (m.HomeTeamID, m.AwayTeamID)

    UNION ALL

    SELECT
        'Duplicate shootout records' AS CheckName,
        COUNT(*) AS ProblemRows
    FROM (
        SELECT
            MatchID,
            WinnerTeamID,
            FirstShooterTeamID,
            COUNT(*) AS DuplicateCount
        FROM dbo.Fact_shootout
        GROUP BY MatchID, WinnerTeamID, FirstShooterTeamID
        HAVING COUNT(*) > 1
    ) d

    UNION ALL

    SELECT
        'Duplicate goalscorer records' AS CheckName,
        COUNT(*) AS ProblemRows
    FROM (
        SELECT
            MatchID,
            ScoringTeamID,
            ScorerName,
            Minute,
            IsOwnGoal,
            IsPenalty,
            COUNT(*) AS DuplicateCount
        FROM dbo.Fact_goalscorer
        GROUP BY MatchID, ScoringTeamID, ScorerName, Minute, IsOwnGoal, IsPenalty
        HAVING COUNT(*) > 1
    ) d
) q;


--------------------------------------------------------
-- STEP 5. CREATE SUMMARY TABLE 01: DATABASE OVERVIEW
------------------------------------------------------------

SELECT
    COUNT(*) AS TotalMatches,
    COUNT(DISTINCT HomeTeamID) AS TeamsAppearingAsHome,
    COUNT(DISTINCT AwayTeamID) AS TeamsAppearingAsAway,
    COUNT(DISTINCT TournamentName) AS Tournaments,
    COUNT(DISTINCT Country) AS HostCountries,
    MIN(MatchDate) AS FirstMatchDate,
    MAX(MatchDate) AS LastMatchDate,
    CAST(AVG(CAST(TotalGoals AS FLOAT)) AS DECIMAL(10,2)) AS MeanGoalsPerMatch,
    CAST(STDEV(CAST(TotalGoals AS FLOAT)) AS DECIMAL(10,2)) AS SDGoalsPerMatch,
    MIN(TotalGoals) AS MinGoalsInMatch,
    MAX(TotalGoals) AS MaxGoalsInMatch
INTO dbo.Summary_01_DatabaseOverview
FROM dbo.v_match_analysis;


----------------------------------------------------------
-- STEP 6. CREATE SUMMARY TABLE 02: MATCH RESULT DISTRIBUTION
-- Myth: home advantage is not absolute.
--------------------------------------------------------

SELECT
    MatchResult,
    COUNT(*) AS Matches,
    CAST(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0) AS DECIMAL(10,2)) AS PercentOfMatches,
INTO dbo.Summary_02_MatchResults
FROM dbo.v_match_analysis
WHERE IsNeutral = 0
GROUP BY MatchResult;


-- ----------------------------------------------------------
-- -- STEP 7. CREATE SUMMARY TABLE 03: HOME ADVANTAGE BY DECADE
-- -- Includes window function LAG.
-- ----------------------------------------------------------
---- nuyn step 6n e uxxaki 10amyaknerov
-- WITH decade_home AS (
--     SELECT
--         MatchDecade,
--         COUNT(*) AS NonNeutralMatches,
--         CAST(100.0 * SUM(CASE WHEN MatchResult = 'Home win' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(10,2)) AS HomeWinPercent,
--         CAST(100.0 * SUM(CASE WHEN MatchResult = 'Away win' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(10,2)) AS AwayWinPercent,
--         CAST(100.0 * SUM(CASE WHEN MatchResult = 'Draw' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(10,2)) AS DrawPercent,
--         CAST(AVG(CAST(TotalGoals AS FLOAT)) AS DECIMAL(10,2)) AS MeanGoals,
--         CAST(STDEV(CAST(TotalGoals AS FLOAT)) AS DECIMAL(10,2)) AS SDGoals
--     FROM dbo.v_match_analysis
--     WHERE IsNeutral = 0
--     GROUP BY MatchDecade
-- )
-- SELECT
--     MatchDecade,
--     NonNeutralMatches,
--     HomeWinPercent,
--     HomeWinPercent - LAG(HomeWinPercent) OVER (ORDER BY MatchDecade) AS ChangeFromPreviousDecade,
--     AwayWinPercent,
--     DrawPercent,
--     MeanGoals,
--     SDGoals
-- INTO dbo.Summary_03_HomeAdvantageByDecade
-- FROM decade_home;


-------------------------------------------------------
-- STEP 8. CREATE SUMMARY TABLE 04: GOALS BY DECADE
-- Myth: football is not simply becoming goalless/boring.
------------------------------------------------------------

WITH decade_goals AS (
    SELECT
        MatchDecade,
        COUNT(*) AS Matches,
        CAST(AVG(CAST(TotalGoals AS FLOAT)) AS DECIMAL(10,2)) AS MeanGoalsPerMatch,
        CAST(STDEV(CAST(TotalGoals AS FLOAT)) AS DECIMAL(10,2)) AS SDGoalsPerMatch,
        MIN(TotalGoals) AS MinGoals,
        MAX(TotalGoals) AS MaxGoals
    FROM dbo.v_match_analysis
    GROUP BY MatchDecade
)
SELECT
    MatchDecade,
    Matches,
    MeanGoalsPerMatch,
    MeanGoalsPerMatch - LAG(MeanGoalsPerMatch) OVER (ORDER BY MatchDecade) AS ChangeFromPreviousDecade,
    SDGoalsPerMatch,
    MinGoals,
    MaxGoals
INTO dbo.Summary_04_GoalsByDecade
FROM decade_goals;


------------------------------------------------------------
-- STEP 9. CREATE SUMMARY TABLE 05: SCORE MARGIN DISTRIBUTION
-- Myth: blowout wins are common.
-----------------------------------------------------------

WITH margin_groups AS (
    SELECT
        CASE
            WHEN GoalDifference = 0 THEN 'Draw'
            WHEN GoalDifference = 1 THEN 'One-goal match'
            WHEN GoalDifference = 2 THEN 'Two-goal match'
            WHEN GoalDifference BETWEEN 3 AND 5 THEN '3-5 goal difference'
            ELSE '6+ goal difference'
        END AS ScoreMarginGroup,
        CASE
            WHEN GoalDifference = 0 THEN 1
            WHEN GoalDifference = 1 THEN 2
            WHEN GoalDifference = 2 THEN 3
            WHEN GoalDifference BETWEEN 3 AND 5 THEN 4
            ELSE 5
        END AS SortOrder,
        GoalDifference
    FROM dbo.v_match_analysis
)
SELECT
    ScoreMarginGroup,
    COUNT(*) AS Matches,
    CAST(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0) AS DECIMAL(10,2)) AS PercentOfMatches,
    CAST(AVG(CAST(GoalDifference AS FLOAT)) AS DECIMAL(10,2)) AS MeanGoalDifference,
    CAST(STDEV(CAST(GoalDifference AS FLOAT)) AS DECIMAL(10,2)) AS SDGoalDifference,
    SortOrder
INTO dbo.Summary_05_ScoreMarginDistribution
FROM margin_groups
GROUP BY ScoreMarginGroup, SortOrder;


----------------------------------------------------------
-- STEP 10. CREATE SUMMARY TABLE 06: GOAL TIMING
-- Myth: most goals happen in the last minutes.
------------------------------------------------------------

SELECT
    MinutePeriod,
    COUNT(*) AS Goals,
    CAST(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0) AS DECIMAL(10,2)) AS PercentOfKnownMinuteGoals,
    CAST(AVG(CAST(Minute AS FLOAT)) AS DECIMAL(10,2)) AS MeanMinute,
    CAST(STDEV(CAST(Minute AS FLOAT)) AS DECIMAL(10,2)) AS SDMinute,
    MIN(Minute) AS MinMinute,
    MAX(Minute) AS MaxMinute,
    MinutePeriodOrder
INTO dbo.Summary_06_GoalTiming
FROM dbo.v_goalscorer_analysis
WHERE Minute IS NOT NULL
GROUP BY MinutePeriod, MinutePeriodOrder;


-----------------------------------------------------------
-- STEP 11. CREATE SUMMARY TABLE 07: GOAL TYPE
-- Myth: penalties or own goals decide most goals.
-----------------------------------------------------

WITH goal_types AS (
    SELECT
        CASE
            WHEN IsPenalty = 1 THEN 'Penalty goal'
            ELSE 'Non-penalty goal'
        END AS GoalType
    FROM dbo.v_goalscorer_analysis

    UNION ALL

    SELECT
        CASE
            WHEN IsOwnGoal = 1 THEN 'Own goal'
            ELSE 'Not own goal'
        END AS GoalType
    FROM dbo.v_goalscorer_analysis
)
SELECT
    GoalType,
    COUNT(*) AS Goals,
    CAST(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM dbo.v_goalscorer_analysis), 0) AS DECIMAL(10,2)) AS PercentOfAllGoalRows
INTO dbo.Summary_07_GoalType
FROM goal_types
GROUP BY GoalType;


-----------------------------------------------------------
-- STEP 12. CREATE SUMMARY TABLE 08: SHOOTOUT FIRST-SHOOTER RESULT
-- Myth: first shooter always wins.
------------------------------------------------------------

SELECT
    FirstShooterResult,
    COUNT(*) AS Shootouts,
    CAST(100.0 * COUNT(*) / NULLIF(SUM(COUNT(*)) OVER (), 0) AS DECIMAL(10,2)) AS PercentOfShootouts,
    CAST(AVG(CAST(FirstShooterWon AS FLOAT)) AS DECIMAL(10,2)) AS MeanFirstShooterWon,
    CAST(STDEV(CAST(FirstShooterWon AS FLOAT)) AS DECIMAL(10,2)) AS SDFirstShooterWon
INTO dbo.Summary_08_ShootoutFirstShooter
FROM dbo.v_shootout_analysis
WHERE FirstShooterTeamID IS NOT NULL
GROUP BY FirstShooterResult;


-----------------------------------------------------------
-- STEP 13. CREATE SUMMARY TABLE 09: TEAM PERFORMANCE
-- Basic team-level performance table.
-- Minimum 100 matches avoids unstable tiny-sample teams.
------------------------------------------------------------

WITH team_matches AS (
    SELECT
        HomeTeamID AS TeamID,
        HomeTeam AS TeamName,
        HomeScore AS GoalsFor,
        AwayScore AS GoalsAgainst,
        CASE WHEN HomeScore > AwayScore THEN 1 ELSE 0 END AS WinFlag,
        CASE WHEN HomeScore = AwayScore THEN 1 ELSE 0 END AS DrawFlag,
        CASE WHEN HomeScore < AwayScore THEN 1 ELSE 0 END AS LossFlag
    FROM dbo.v_match_analysis

    UNION ALL

    SELECT
        AwayTeamID AS TeamID,
        AwayTeam AS TeamName,
        AwayScore AS GoalsFor,
        HomeScore AS GoalsAgainst,
        CASE WHEN AwayScore > HomeScore THEN 1 ELSE 0 END AS WinFlag,
        CASE WHEN AwayScore = HomeScore THEN 1 ELSE 0 END AS DrawFlag,
        CASE WHEN AwayScore < HomeScore THEN 1 ELSE 0 END AS LossFlag
    FROM dbo.v_match_analysis
),
team_summary AS (
    SELECT
        TeamID,
        TeamName,
        COUNT(*) AS MatchesPlayed,
        SUM(WinFlag) AS Wins,
        SUM(DrawFlag) AS Draws,
        SUM(LossFlag) AS Losses,
        SUM(GoalsFor) AS GoalsFor,
        SUM(GoalsAgainst) AS GoalsAgainst,
        SUM(GoalsFor) - SUM(GoalsAgainst) AS GoalDifference,
        CAST(100.0 * SUM(WinFlag) / NULLIF(COUNT(*), 0) AS DECIMAL(10,2)) AS WinPercent,
        CAST(AVG(CAST(GoalsFor AS FLOAT)) AS DECIMAL(10,2)) AS MeanGoalsFor,
        CAST(STDEV(CAST(GoalsFor AS FLOAT)) AS DECIMAL(10,2)) AS SDGoalsFor,
        CAST(AVG(CAST(GoalsAgainst AS FLOAT)) AS DECIMAL(10,2)) AS MeanGoalsAgainst,
        CAST(STDEV(CAST(GoalsAgainst AS FLOAT)) AS DECIMAL(10,2)) AS SDGoalsAgainst
    FROM team_matches
    GROUP BY TeamID, TeamName
    HAVING COUNT(*) >= 100
)
SELECT
    RANK() OVER (ORDER BY WinPercent DESC, GoalDifference DESC, GoalsFor DESC) AS TeamRank,
    TeamName,
    MatchesPlayed,
    Wins,
    Draws,
    Losses,
    GoalsFor,
    GoalsAgainst,
    GoalDifference,
    WinPercent,
    MeanGoalsFor,
    SDGoalsFor,
    MeanGoalsAgainst,
    SDGoalsAgainst
INTO dbo.Summary_09_TeamPerformance
FROM team_summary;


------------------------------------------------------------
-- STEP 14. CREATE SUMMARY TABLE 10: TOURNAMENT SCORING
-- Myth: World Cup is always the highest scoring tournament.
-- Minimum 100 matches avoids very small tournaments.
------------------------------------------------------------

SELECT
    TournamentName,
    COUNT(*) AS Matches,
    CAST(AVG(CAST(TotalGoals AS FLOAT)) AS DECIMAL(10,2)) AS MeanGoalsPerMatch,
    CAST(STDEV(CAST(TotalGoals AS FLOAT)) AS DECIMAL(10,2)) AS SDGoalsPerMatch,
    MIN(TotalGoals) AS MinGoals,
    MAX(TotalGoals) AS MaxGoals
INTO dbo.Summary_10_TournamentScoring
FROM dbo.v_match_analysis
GROUP BY TournamentName
HAVING COUNT(*) >= 100;


------------------------------------------------------------
-- STEP 15. CREATE SUMMARY TABLE 11: TOP SCORERS
-- Simple scorer-level descriptive table.
------------------------------------------------------------

SELECT
    ScorerName,
    COUNT(*) AS TotalGoals,
    SUM(CASE WHEN IsPenalty = 1 THEN 1 ELSE 0 END) AS PenaltyGoals,
    SUM(CASE WHEN IsOwnGoal = 1 THEN 1 ELSE 0 END) AS OwnGoals,
    CAST(AVG(CAST(Minute AS FLOAT)) AS DECIMAL(10,2)) AS MeanScoringMinute,
    CAST(STDEV(CAST(Minute AS FLOAT)) AS DECIMAL(10,2)) AS SDScoringMinute
INTO dbo.Summary_11_TopScorers
FROM dbo.v_goalscorer_analysis
WHERE IsOwnGoal = 0
GROUP BY ScorerName
HAVING COUNT(*) >= 10;


------------------------------------------------------------
-- STEP 16. DISPLAY FINAL TABLES
-- These are the tables to use for report/presentation.
------------------------------------------------------------

SELECT * FROM dbo.Summary_00_DataQualityStatus;

SELECT * FROM dbo.Summary_01_DatabaseOverview;

SELECT
    MatchResult,
    Matches,
    PercentOfMatches,
    MeanTotalGoals,
    SDTotalGoals
FROM dbo.Summary_02_MatchResults
ORDER BY Matches DESC;

SELECT *
FROM dbo.Summary_03_HomeAdvantageByDecade
ORDER BY MatchDecade;

SELECT *
FROM dbo.Summary_04_GoalsByDecade
ORDER BY MatchDecade;

SELECT
    ScoreMarginGroup,
    Matches,
    PercentOfMatches,
    MeanGoalDifference,
    SDGoalDifference
FROM dbo.Summary_05_ScoreMarginDistribution
ORDER BY SortOrder;

SELECT
    MinutePeriod,
    Goals,
    PercentOfKnownMinuteGoals,
    MeanMinute,
    SDMinute,
    MinMinute,
    MaxMinute
FROM dbo.Summary_06_GoalTiming
ORDER BY MinutePeriodOrder;

SELECT *
FROM dbo.Summary_07_GoalType
ORDER BY Goals DESC;

SELECT *
FROM dbo.Summary_08_ShootoutFirstShooter
ORDER BY Shootouts DESC;

SELECT TOP 20 *
FROM dbo.Summary_09_TeamPerformance
ORDER BY TeamRank;

SELECT TOP 20 *
FROM dbo.Summary_10_TournamentScoring
ORDER BY MeanGoalsPerMatch DESC, Matches DESC;

SELECT TOP 20 *
FROM dbo.Summary_11_TopScorers
ORDER BY TotalGoals DESC, PenaltyGoals DESC;
