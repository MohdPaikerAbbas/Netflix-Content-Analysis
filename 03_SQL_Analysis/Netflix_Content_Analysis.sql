-- Create Database
CREATE DATABASE netflix_content_analysis;

-- Use Database
USE netflix_content_analysis;

CREATE TABLE netflix_genre_analysis (
    show_id VARCHAR(20),
    genre VARCHAR(100)
);

INSERT INTO netflix_genre_analysis (show_id, genre)
SELECT
    n.show_id,
    TRIM(j.genre)
FROM netflix_titles n
JOIN JSON_TABLE(
    CONCAT(
        '["',
        REPLACE(REPLACE(n.listed_in, '"', '\\"'), ',', '","'),
        '"]'
    ),
    '$[*]' COLUMNS (
        genre VARCHAR(100) PATH '$'
    )
) j
WHERE n.listed_in IS NOT NULL
  AND TRIM(n.listed_in) <> '';
  
  SELECT genre AS Genre,
       COUNT(DISTINCT show_id) AS Total_Titles
FROM netflix_genre_analysis
GROUP BY genre
ORDER BY Total_Titles DESC
LIMIT 10;

SHOW VARIABLES LIKE 'local_infile';

CREATE TABLE netflix_country_analysis (
    show_id VARCHAR(20),
    country VARCHAR(100)
);

INSERT INTO netflix_country_analysis (show_id, country)
SELECT
    n.show_id,
    TRIM(j.country)
FROM netflix_titles n
JOIN JSON_TABLE(
    CONCAT(
        '["',
        REPLACE(REPLACE(n.country, '"', '\\"'), ',', '","'),
        '"]'
    ),
    '$[*]' COLUMNS (
        country VARCHAR(100) PATH '$'
    )
) j
WHERE n.country IS NOT NULL
  AND TRIM(n.country) <> ''
  AND TRIM(n.country) <> 'Unknown';
  
  SELECT country, COUNT(DISTINCT show_id) AS Total_Titles
FROM netflix_country_analysis
GROUP BY country
ORDER BY Total_Titles DESC
LIMIT 10;

  
-- Create table for cleaned Netflix dataset
CREATE TABLE netflix_titles (
    show_id VARCHAR(20),
    type VARCHAR(20),
    title VARCHAR(255),
    director TEXT,
    `cast` TEXT,
    country TEXT,
    date_added VARCHAR(30),
    release_year INT,
    rating VARCHAR(20),
    duration VARCHAR(30),
    listed_in TEXT,
    description TEXT,
    date_added_year INT,
    date_added_month VARCHAR(20),
    movie_duration_min INT,
    tv_seasons INT,
    movie_duration_group VARCHAR(30)
);

-- Check table structure
DESCRIBE netflix_titles;

-- Import Netflix data and convert blank numeric values to NULL
LOAD DATA LOCAL INFILE 'C:/Users/Dell/OneDrive/Desktop/Netflix_Content_Analysis_Project/03_SQL_Analysis/netflix_titles_cleaned.csv'
INTO TABLE netflix_titles
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(show_id, type, title, director, @cast, country, date_added,
 release_year, rating, duration, listed_in, description,
 @date_added_year, date_added_month, @movie_duration_min,
 @tv_seasons, movie_duration_group)
SET
`cast` = @cast,
date_added_year = NULLIF(@date_added_year, ''),
movie_duration_min = NULLIF(@movie_duration_min, ''),
tv_seasons = NULLIF(@tv_seasons, '');

-- Validate total number of Netflix records
SELECT COUNT(*) AS total_records
FROM netflix_titles;

-- Check for duplicate Show IDs
SELECT show_id, COUNT(*) AS duplicate_count
FROM netflix_titles
GROUP BY show_id
HAVING COUNT(*) > 1;

-- Check NULL values in important columns
SELECT
    SUM(show_id IS NULL) AS show_id_nulls,
    SUM(type IS NULL) AS type_nulls,
    SUM(title IS NULL) AS title_nulls,
    SUM(director IS NULL) AS director_nulls,
    SUM(`cast` IS NULL) AS cast_nulls,
    SUM(country IS NULL) AS country_nulls,
    SUM(date_added IS NULL OR date_added = '') AS date_added_missing,
    SUM(release_year IS NULL) AS release_year_nulls,
    SUM(rating IS NULL) AS rating_nulls,
    SUM(duration IS NULL) AS duration_nulls
FROM netflix_titles;

-- Validate Netflix content types and their record counts
SELECT type, COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY type;

-- Validate minimum and maximum release year
SELECT
    MIN(release_year) AS earliest_release_year,
    MAX(release_year) AS latest_release_year
FROM netflix_titles;

-- Validate Movie duration and TV season helper columns
SELECT
    SUM(movie_duration_min IS NULL) AS movie_duration_nulls,
    SUM(tv_seasons IS NULL) AS tv_seasons_nulls,
    COUNT(movie_duration_min) AS movie_duration_records,
    COUNT(tv_seasons) AS tv_season_records
FROM netflix_titles;

-- Validate rating categories and record counts
SELECT rating, COUNT(*) AS total_titles
FROM netflix_titles
GROUP BY rating
ORDER BY total_titles DESC;

-- Validate date_added values before converting to DATE
SELECT
    MIN(STR_TO_DATE(NULLIF(date_added, ''), '%d-%m-%Y')) AS earliest_date_added,
    MAX(STR_TO_DATE(NULLIF(date_added, ''), '%d-%m-%Y')) AS latest_date_added,
    SUM(date_added = '' OR date_added IS NULL) AS missing_dates
FROM netflix_titles;

-- ----------------------------------------------(BUSINESS ANALYSIS)------------------------------------------------------------------------------------------------

-- BUSINESS ANALYSIS 1: CONTENT LIBRARY OVERVIEW
-- Business Question: What is the total number of titles available on Netflix?
-- Calculates the total number of movies and TV shows in the Netflix dataset.

SELECT COUNT(*) AS Total_Titles FROM netflix_titles;

-- BUSINESS ANALYSIS 2: CONTENT DISTRIBUTION BY TYPE
-- Business Question: How is Netflix's content library distributed between Movies and TV Shows?
-- Calculates the total number of titles for each content type.

SELECT Type, COUNT(*) AS Total_Titles
FROM netflix_titles
GROUP BY Type
ORDER BY Total_Titles DESC;

-- BUSINESS ANALYSIS 3: CONTENT ADDED BY YEAR
-- Business Question: How many titles were added to Netflix each year?
-- Calculates the number of titles added to Netflix for each available year.

SELECT YEAR(date_added) AS Year_Added, COUNT(*) AS Total_Titles
FROM netflix_titles
WHERE date_added IS NOT NULL
GROUP BY YEAR(date_added)
ORDER BY Year_Added;

-- BUSINESS ANALYSIS 4: CONTENT DISTRIBUTION BY RATING
-- Business Question: Which content ratings have the highest number of titles on Netflix?
-- Calculates the number of titles under each rating and ranks them from highest to lowest.

SELECT Rating, COUNT(*) AS Total_Titles
FROM netflix_titles
GROUP BY Rating
ORDER BY Total_Titles DESC;

-- BUSINESS ANALYSIS 5: TOP 10 COUNTRIES BY CONTENT COUNT
-- Business Question: Which countries have produced the highest number of Netflix titles?
-- Identifies the top 10 countries with the largest number of Movies and TV Shows.

SELECT country AS Country, COUNT(*) AS Total_Titles
FROM netflix_titles
WHERE country IS NOT NULL
GROUP BY country
ORDER BY Total_Titles DESC
LIMIT 10;

-- BUSINESS ANALYSIS 6: CONTENT TYPE DISTRIBUTION BY RATING
-- Business Question: How are Movies and TV Shows distributed across different content ratings?
-- Compares the number of Movies and TV Shows available under each rating category.

SELECT rating AS Rating, type AS Content_Type, COUNT(*) AS Total_Titles
FROM netflix_titles
GROUP BY rating, type
ORDER BY Rating, Total_Titles DESC;

-- BUSINESS ANALYSIS 7: RELEASE YEAR DISTRIBUTION
-- Business Question: How many Netflix titles were released in each year?
-- Calculates the number of Movies and TV Shows released each year.

SELECT release_year AS Release_Year, COUNT(*) AS Total_Titles
FROM netflix_titles
GROUP BY release_year
ORDER BY Release_Year;


-- BUSINESS ANALYSIS 8: TOP 10 RELEASE YEARS
-- Business Question: Which release years have the highest number of Netflix titles?
-- Identifies the top 10 release years with the largest number of titles.

SELECT release_year AS Release_Year, COUNT(*) AS Total_Titles
FROM netflix_titles
GROUP BY release_year
ORDER BY Total_Titles DESC
LIMIT 10;


-- BUSINESS ANALYSIS 9: MOVIE DURATION DISTRIBUTION
-- Business Question: How are Netflix Movies distributed across different duration groups?
-- Calculates the number of Movies available in each movie duration category.

SELECT movie_duration_group AS Duration_Group, COUNT(*) AS Total_Movies
FROM netflix_titles
WHERE type = 'Movie'
  AND movie_duration_group IS NOT NULL
GROUP BY movie_duration_group
ORDER BY Total_Movies DESC;


-- BUSINESS ANALYSIS 10: AVERAGE MOVIE DURATION
-- Business Question: What is the average duration of Movies available on Netflix?
-- Calculates the average running time of Netflix Movies in minutes.

SELECT ROUND(AVG(movie_duration_min), 2) AS Average_Movie_Duration_Minutes
FROM netflix_titles
WHERE type = 'Movie'
  AND movie_duration_min IS NOT NULL;


-- BUSINESS ANALYSIS 11: LONGEST MOVIES
-- Business Question: Which are the 10 longest Movies available in the Netflix dataset?
-- Identifies the top 10 Movies based on their running time in minutes.

SELECT title AS Movie_Title, movie_duration_min AS Duration_Minutes
FROM netflix_titles
WHERE type = 'Movie'
  AND movie_duration_min IS NOT NULL
ORDER BY movie_duration_min DESC
LIMIT 10;


-- BUSINESS ANALYSIS 12: TV SHOW DISTRIBUTION BY SEASONS
-- Business Question: How are Netflix TV Shows distributed according to their number of seasons?
-- Calculates the number of TV Shows available for each season count.

SELECT tv_seasons AS Number_of_Seasons, COUNT(*) AS Total_TV_Shows
FROM netflix_titles
WHERE type = 'TV Show'
  AND tv_seasons IS NOT NULL
GROUP BY tv_seasons
ORDER BY Number_of_Seasons;


-- BUSINESS ANALYSIS 13: LONGEST RUNNING TV SHOWS
-- Business Question: Which TV Shows have the highest number of seasons on Netflix?
-- Identifies the top 10 TV Shows based on their number of seasons.

SELECT title AS TV_Show_Title, tv_seasons AS Number_of_Seasons
FROM netflix_titles
WHERE type = 'TV Show'
  AND tv_seasons IS NOT NULL
ORDER BY tv_seasons DESC
LIMIT 10;


-- BUSINESS ANALYSIS 14: CONTENT ADDED BY MONTH
-- Business Question: During which months does Netflix add the most content?
-- Calculates the total number of titles added in each calendar month.

SELECT MONTHNAME(date_added) AS Month_Name,
       COUNT(*) AS Total_Titles
FROM netflix_titles
WHERE date_added IS NOT NULL
GROUP BY MONTH(date_added), MONTHNAME(date_added)
ORDER BY MONTH(date_added);


-- BUSINESS ANALYSIS 15: MOST ACTIVE CONTENT ADDITION MONTH
-- Business Question: Which month has historically received the highest number of Netflix title additions?
-- Identifies the calendar month with the highest total number of titles added.

SELECT MONTHNAME(date_added) AS Month_Name,
       COUNT(*) AS Total_Titles
FROM netflix_titles
WHERE date_added IS NOT NULL
GROUP BY MONTH(date_added), MONTHNAME(date_added)
ORDER BY Total_Titles DESC
LIMIT 1;


-- BUSINESS ANALYSIS 16: CONTENT RELEASED BY DECADE
-- Business Question: How is Netflix content distributed across different release decades?
-- Groups titles into decades based on their original release year.

SELECT 
    CONCAT(FLOOR(release_year / 10) * 10, 's') AS Release_Decade,
    COUNT(*) AS Total_Titles
FROM netflix_titles
GROUP BY Release_Decade
ORDER BY Release_Decade;

-- BUSINESS ANALYSIS 17: TOP 10 DIRECTORS
-- Business Question: Which directors have the highest number of titles in the Netflix dataset?
-- Identifies the top 10 director entries while excluding records where the director is Unknown.

SELECT director AS Director, COUNT(*) AS Total_Titles
FROM netflix_titles
WHERE director IS NOT NULL
  AND director <> 'Unknown'
GROUP BY director
ORDER BY Total_Titles DESC
LIMIT 10;


-- BUSINESS ANALYSIS 18: CONTENT TYPE BY RELEASE DECADE
-- Business Question: How has the distribution of Movies and TV Shows changed across release decades?
-- Compares the number of Movies and TV Shows released within each decade.

SELECT 
    CONCAT(FLOOR(release_year / 10) * 10, 's') AS Release_Decade,
    type AS Content_Type,
    COUNT(*) AS Total_Titles
FROM netflix_titles
GROUP BY Release_Decade, Content_Type
ORDER BY Release_Decade, Content_Type;


-- BUSINESS ANALYSIS 19: CONTENT ADDITION TREND BY TYPE
-- Business Question: How has Netflix's addition of Movies and TV Shows changed over the years?
-- Calculates yearly content additions separately for Movies and TV Shows.

SELECT YEAR(date_added) AS Year_Added,
       type AS Content_Type,
       COUNT(*) AS Total_Titles
FROM netflix_titles
WHERE date_added IS NOT NULL
GROUP BY YEAR(date_added), type
ORDER BY Year_Added, Content_Type;


-- BUSINESS ANALYSIS 20: AVERAGE RELEASE-TO-NETFLIX GAP
-- Business Question: On average, how many years after release are titles added to Netflix?
-- Calculates the average difference between a title's release year and the year it was added to Netflix.

SELECT ROUND(AVG(YEAR(date_added) - release_year), 2) AS Average_Years_to_Add
FROM netflix_titles
WHERE date_added IS NOT NULL
  AND YEAR(date_added) >= release_year;


-- BUSINESS ANALYSIS 21: RELEASE-TO-NETFLIX GAP BY CONTENT TYPE
-- Business Question: Does the average time taken to add content differ between Movies and TV Shows?
-- Compares the average release-to-Netflix gap for Movies and TV Shows.

SELECT type AS Content_Type,
       ROUND(AVG(YEAR(date_added) - release_year), 2) AS Average_Years_to_Add
FROM netflix_titles
WHERE date_added IS NOT NULL
  AND YEAR(date_added) >= release_year
GROUP BY type
ORDER BY Average_Years_to_Add DESC;


-- BUSINESS ANALYSIS 22: TITLES ADDED IN THEIR RELEASE YEAR
-- Business Question: How many titles were added to Netflix in the same year they were released?
-- Calculates same-year additions separately for Movies and TV Shows.

SELECT type AS Content_Type,
       COUNT(*) AS Same_Year_Additions
FROM netflix_titles
WHERE date_added IS NOT NULL
  AND YEAR(date_added) = release_year
GROUP BY type
ORDER BY Same_Year_Additions DESC;


-- BUSINESS ANALYSIS 23: YEARLY CONTENT GROWTH
-- Business Question: How did the number of titles added to Netflix change compared with the previous year?
-- Uses a window function to compare yearly title additions and calculate the year-over-year change.

WITH Yearly_Content AS (
    SELECT YEAR(date_added) AS Year_Added,
           COUNT(*) AS Total_Titles
    FROM netflix_titles
    WHERE date_added IS NOT NULL
    GROUP BY YEAR(date_added)
)
SELECT Year_Added,
       Total_Titles,
       LAG(Total_Titles) OVER (ORDER BY Year_Added) AS Previous_Year_Titles,
       Total_Titles - LAG(Total_Titles) OVER (ORDER BY Year_Added) AS Yearly_Change
FROM Yearly_Content
ORDER BY Year_Added;


-- BUSINESS ANALYSIS 24: RANK RELEASE YEARS BY CONTENT VOLUME
-- Business Question: How do release years rank according to the number of titles in the Netflix library?
-- Uses a window function to rank release years from highest to lowest based on total titles.

WITH Release_Year_Content AS (
    SELECT release_year AS Release_Year,
           COUNT(*) AS Total_Titles
    FROM netflix_titles
    GROUP BY release_year
)
SELECT Release_Year,
       Total_Titles,
       DENSE_RANK() OVER (ORDER BY Total_Titles DESC) AS Content_Rank
FROM Release_Year_Content
ORDER BY Content_Rank, Release_Year;


-- BUSINESS ANALYSIS 25: CONTENT TYPE PERCENTAGE BY YEAR
-- Business Question: What percentage of yearly Netflix additions consisted of Movies versus TV Shows?
-- Calculates each content type's percentage contribution to the total titles added in each year.

SELECT YEAR(date_added) AS Year_Added,
       type AS Content_Type,
       COUNT(*) AS Total_Titles,
       ROUND(
           COUNT(*) * 100.0 /
           SUM(COUNT(*)) OVER (PARTITION BY YEAR(date_added)),
           2
       ) AS Percentage_of_Year
FROM netflix_titles
WHERE date_added IS NOT NULL
GROUP BY YEAR(date_added), type
ORDER BY Year_Added, Total_Titles DESC;

