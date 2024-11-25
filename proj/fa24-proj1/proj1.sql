-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era) AS
 SELECT MAX(era)
 FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT nameFirst, nameLast, birthYear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
    SELECT nameFirst, nameLast, birthYear
    FROM people
    WHERE nameFirst LIKE '% %'
    ORDER BY nameFirst, nameLast
;

-- Question 1iii
-- iii. From the people table, group together players with the same birthyear, and report the birthyear, average height,
-- and number of players for each birthyear. Order the results by birthyear in ascending order.
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
    SELECT birthYear, AVG(height), count(*)
    FROM people
    GROUP BY birthYear
    order by birthYear
;

-- Question 1iv
-- iv. Following the results of part iii, now only include groups with an average height > 70. Again order the results
-- by birthyear in ascending order.
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
    SELECT birthYear, AVG(height) AS avgheight, count(*)
    FROM people
    GROUP BY birthYear
    HAVING avgheight > 70
    ORDER BY birthYear
;

-- Question 2i
-- i. Find the namefirst, namelast, playerid and yearid of all people who were successfully inducted into the Hall of
-- Fame in descending order of yearid. Break ties on yearid by playerid (ascending).
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
    SELECT nameFirst, nameLast, p.playerID, h.yearid
    FROM halloffame AS h, people AS p
    WHERE h.playerID == p.playerID
    AND h.inducted == 'Y'
    ORDER BY h.yearid DESC, p.playerID ASC
;

-- Question 2ii
-- ii. Find the people who were successfully inducted into the Hall of Fame and played in college at a school located in
-- the state of California. For each person, return their namefirst, namelast, playerid, schoolid, and yearid in
-- descending order of yearid. Break ties on yearid by schoolid, playerid (ascending). For this question, yearid refers
-- to the year of induction into the Hall of Fame.
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
--     SELECT DISTINCT schoolState,1,1,1,1 FROM schools
    SELECT p.nameFirst, p.nameLast, p.playerID, c.schoolID, h.yearid
    FROM people AS p, schools AS s, collegeplaying AS c, halloffame AS h
    WHERE h.playerID == p.playerID
    AND h.playerID == c.playerid
    AND c.schoolID == s.schoolID
    AND s.schoolState == 'CA'
    AND h.inducted == 'Y'
    ORDER BY h.yearid DESC
;

-- Question 2iii
-- iii. Find the playerid, namefirst, namelast and schoolid of all people who were successfully inducted into the Hall
-- of Fame -- whether or not they played in college. Return people in descending order of playerid. Break ties on
-- playerid by schoolid (ascending). (Note: schoolid should be NULL if they did not play in college.)
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
    SELECT q2i.playerid, q2i.namefirst, q2i.namelast, c.schoolID
    FROM collegeplaying AS c RIGHT OUTER JOIN q2i
    ON c.playerid == q2i.playerid
    ORDER BY q2i.playerid DESC, c.schoolID ASC
;

-- Question 3i
-- i. Find the playerid, namefirst, namelast, yearid and single-year slg (Slugging Percentage) of the players with the
-- 10 best annual Slugging Percentage recorded over all time. A player can appear multiple times in the output. For
-- example, if Babe Ruth’s slg in 2000 and 2001 both landed in the top 10 best annual Slugging Percentage of all time,
-- then we should include Babe Ruth twice in the output. For statistical significance, only include players with more
-- than 50 at-bats in the season. Order the results by slg descending, and break ties by yearid, playerid (ascending).
--
-- Baseball note: Slugging Percentage is not provided in the database; it is computed according to a simple formula you
-- can calculate from the data in the database.

-- SQL note: You should compute slg properly as a floating point number---you'll need to figure out how to convince SQL
-- to do this!

-- Data set note: The online documentation batting mentions two columns 2B and 3B. On your local copy of the data set
-- these have been renamed H2B and H3B respectively (columns starting with numbers are tedious to write queries on).
--
-- Data set note: The column H of the batting table represents all hits = (# singles) + (# doubles) + (# triples) +
-- (# home runs), not just (# singles) so you’ll need to account for some double-counting
--
-- If a player played on multiple teams during the same season (for example anderma02 in 2006) treat their time on each
-- team separately for this calculation
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
    SELECT b.playerID, p.nameFirst, p.nameLast, b.yearID,
           CAST(
                   (H - H2B - H3B - HR + 2 * H2B + 3 * H3B + 4 * HR
                       ) AS FLOAT
           ) / NULLIF(AB, 0) AS slg
    FROM batting AS b, people AS p
    WHERE b.playerID = p.playerID
    AND b.AB > 50
    ORDER BY slg DESC, b.yearID, b.playerID
    LIMIT 10
;

-- Question 3ii
-- ii. Following the results from Part i, find the playerid, namefirst, namelast and lslg (Lifetime Slugging Percentage)
-- for the players with the top 10 Lifetime Slugging Percentage. Lifetime Slugging Percentage (LSLG) uses the same
-- formula as Slugging Percentage (SLG), but it uses the number of singles, doubles, triples, home runs, and at bats
-- each player has over their entire career, rather than just over a single season.
--
-- Note that the database only gives batting information broken down by year; you will need to convert to total
-- information across all time (from the earliest date recorded up to the last date recorded) to compute lslg. Order the
-- results by lslg (descending) and break ties by playerid (ascending)
--
-- Note: Make sure that you only include players with more than 50 at-bats across their lifetime.
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
    SELECT p.playerID, p.nameFirst, p.nameLast,
           CAST(
           (
               totalH - totalH2B - totalH3B - totalHR + 2 * totalH2B + 3 * totalH3B + 4 * totalHR
               ) AS FLOAT
           ) / NULLIF(totalAB, 0) AS lslg
    FROM people AS p, (
        SELECT playerID, SUM(H) AS totalH, SUM(H2B) AS totalH2B, SUM(H3B) AS totalH3B,
               SUM(HR) AS totalHR, SUM(AB) AS totalAB
        FROM batting
        GROUP BY playerID
        HAVING totalAB > 50
    ) AS lb
    WHERE lb.playerID = p.playerID
    ORDER BY lslg DESC, p.playerID
    LIMIT 10
;

-- Question 3iii
-- iii. Find the namefirst, namelast and Lifetime Slugging Percentage (lslg) of batters whose lifetime slugging
-- percentage is higher than that of San Francisco favorite Willie Mays.
--
-- You may include Willie Mays' playerid in your query (mayswi01), but you may not include his slugging percentage --
-- you should calculate that as part of the query. (Test your query by replacing mayswi01 with the playerid of another
-- player -- it should work for that player as well! We may do the same in the autograder.)
--
-- Note: Make sure that you still only include players with more than 50 at-bats across their lifetime.
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
    WITH tblslg AS (
        SELECT p.playerID, p.nameFirst, p.nameLast,
               CAST(
                       (
                           totalH - totalH2B - totalH3B - totalHR + 2 * totalH2B + 3 * totalH3B + 4 * totalHR
                           ) AS FLOAT
               ) / NULLIF(totalAB, 0) AS lslg
        FROM people AS p, (
            SELECT playerID, SUM(H) AS totalH, SUM(H2B) AS totalH2B, SUM(H3B) AS totalH3B,
                   SUM(HR) AS totalHR, SUM(AB) AS totalAB
            FROM batting
            GROUP BY playerID
            HAVING totalAB > 50
        ) AS lb
        WHERE lb.playerID = p.playerID
        ORDER BY lslg DESC, p.playerID
    )
    SELECT nameFirst, nameLast, lslg
    FROM tblslg
    WHERE lslg > (SELECT lslg FROM tblslg WHERE tblslg.playerID = 'mayswi01')
;

-- Question 4i
-- i. Find the yearid, min, max and average of all player salaries for each year recorded, ordered by yearid in
-- ascending order.
CREATE VIEW q4i(yearid, min, max, avg)
AS
    SELECT yearID, MIN(salary), MAX(salary), AVG(salary)
    FROM salaries AS s
    GROUP BY yearID
    ORDER BY yearID
;

-- Question 4ii
-- ii. For salaries in 2016, compute a histogram. Divide the salary range into 10 equal bins from min to max, with
-- binids 0 through 9, and count the salaries in each bin. Return the binid, low and high boundaries for each bin, as
-- well as the number of salaries in each bin, with results sorted from smallest bin to largest.
--
-- Note: binid 0 corresponds to the lowest salaries, and binid 9 corresponds to the highest. The ranges are
-- left-inclusive (i.e. [low, high)) -- so the high value is excluded. For example, if bin 2 has a high value of 100000,
-- salaries of 100000 belong in bin 3, and bin 3 should have a low value of 100000.
--
-- Note: The high value for bin 9 may be inclusive).
--
-- Note: The test for this question is broken into two parts. Use python3 test.py -q 4ii_bins_0_to_8 and python3 test.py
-- -q 4ii_bin_9 to run the tests
--
-- Hidden testing advice: we will be testing the case where a bin has zero player salaries in it. The correct behavior
-- in this case is to display the correct binid, low and high with a count of zero, NOT just excluding the bin
-- altogether.
CREATE VIEW q4ii(binid, low, high, count)
AS
    WITH salaryrange AS (
        SELECT MIN(salary) AS minsalary, MAX(salary) as maxsalary, (MAX(salary) - MIN(salary)) / 10.0 AS binsize
        FROM salaries
        WHERE yearID = 2016
    ),
        bins AS (
        SELECT
            binid,
            minsalary + binid * binsize AS low,
            CASE
                WHEN binid = 9 THEN maxsalary + 0.01
                ELSE minsalary + (binid + 1) * binsize
            END AS high
        FROM salaryrange, binids
    )

    SELECT binid, low, high, COUNT(s.salary)
    FROM bins AS b
    LEFT JOIN salaries AS s
    ON s.yearID = 2016
    AND s.salary >= low
    AND s.salary < high
    GROUP BY binid, low, high
    ORDER BY binid
;

-- Question 4iii
-- iii. Now let's compute the Year-over-Year change in min, max and average player salary. For each year with recorded
-- salaries after the first, return the yearid, mindiff, maxdiff, and avgdiff with respect to the previous year. Order
-- the output by yearid in ascending order. (You should omit the very first year of recorded salaries from the result.)
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
    SELECT
        thisyear.yearid,
         CAST((thisyear.min - lastyear.min) AS FLOAT),
         CAST((thisyear.max - lastyear.max) AS FLOAT),
         CAST((thisyear.avg - lastyear.avg) AS FLOAT)
    FROM q4i AS thisyear
    JOIN q4i AS lastyear ON thisyear.yearid = lastyear.yearid + 1
    ORDER BY thisyear.yearid
;

-- Question 4iv
-- iv. In 2001, the max salary went up by over $6 million. Write a query to find the players that had the max salary in
-- 2000 and 2001. Return the playerid, namefirst, namelast, salary and yearid for those two years. If multiple players
-- tied for the max salary in a year, return all of them.
--
-- Note on notation: you are computing a relational variant of the argmax for each of those two years.
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
    SELECT tbmax.playerID, p.nameFirst, p.nameLast, tbmax.salary, tbmax.yearID
    FROM people AS p, (
        SELECT s.playerID, s.salary, s.yearID
        FROM salaries AS s, q4i
        WHERE s.yearID = q4i.yearid
        AND s.salary = q4i.max
        AND q4i.yearid IN (2000,2001)
    ) AS tbmax
    WHERE tbmax.playerID = p.playerID
;

-- Question 4v
-- v. Each team has at least 1 All Star and may have multiple. For each team in the year 2016, give the teamid and
-- diffAvg (the difference between the team's highest paid all-star's salary and the team's lowest paid all-star's
-- salary).
--
-- Note: Due to some discrepancies in the database, please draw your team names from the All-Star table (so use
-- allstarfull.teamid in the SELECT statement for this).
CREATE VIEW q4v(team, diffAvg) AS
    SELECT teamID, maxsalary - minsalary
    FROM (
             SELECT teamID, team_ID, MAX(salary) AS maxsalary, MIN(salary) AS minsalary
             FROM (
                      SELECT a.teamID, a.team_ID, s.salary
                      FROM allstarfull AS a, salaries AS s
                      WHERE a.playerID = s.playerID
                        AND a.team_ID = s.team_ID
                        AND a.yearID = s.yearID
                        AND a.yearID = 2016
                  )
             GROUP BY teamID, team_ID
         )
;

