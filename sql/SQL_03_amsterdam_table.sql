/* ============================================================
   Project:  Guest experience in historic hotels
   File:     03_create_amsterdam_table.sql
   Purpose:  Copy Amsterdam reviews into a separate working table
   Author:   Ana Juric
   Dates:     6 Nov 2026 and 9 Nov 2026
   ============================================================ */
   USE hotel_reviews;

-- Create a new table with only the Amsterdam rows (all columns, still as text)
SELECT *
INTO dbo.amsterdam_reviews_raw
FROM dbo.hotel_reviews_raw
WHERE Hotel_Address LIKE '%Netherlands'
-- Result 6 Nov 2026: 57214 rows affected

-- Check: should be 57,214 (from check 3)
SELECT COUNT(*) AS row_count
FROM dbo.amsterdam_reviews_raw
-- Result 6 Nov 2026: 57214 - OK

-- Check 6a: Duplicate reviews in Amsterdam
-- Definition: same hotel, date, nationality, score, positive and negative text
SELECT 
	Hotel_Name,
	Review_Date,
	Reviewer_Nationality,
	Reviewer_Score,
	Negative_Review,
	Positive_Review,
	COUNT(*) AS times_found
FROM dbo.amsterdam_reviews_raw
GROUP BY 
	Hotel_Name,
	Review_Date,
	Reviewer_Nationality,
	Reviewer_Score,
	Negative_Review,
	Positive_Review
HAVING COUNT(*) > 1
ORDER BY times_found DESC
-- Result 6 Nov 2026: 
-- 12 duplicate groups, each found 2 times = 24 rows, of which 12 are extra copies (0.02% of 57,214)
-- Long identical texts (e.g. Krasnapolsky, The Student Hotel): certain duplicates
-- Short texts with placeholders (e.g. Fletcher Hotel): uncertain, could be 2 different guests --> see check 6b
-- Uncertain case: Best Western Premier Hotel Couture, 8/24/2015, Egypt, 9.6 - same complaint,
					-- 2 slightly different positive reviews ("everything is perfect" / "Everything was perfect"),
					-- each found twice = 4 rows. Possibly the same guest; treated as 2 reviews under our definition)

-- Check 6b: Duplicate reviews in Amsterdam
-- Definition: same hotel, date, nationality, score, tags, positive and negative text
SELECT 
	Hotel_Name,
	Review_Date,
	Reviewer_Nationality,
	Reviewer_Score,
	Tags,
	Positive_Review,
	Negative_Review,
	COUNT(*) AS times_found
FROM amsterdam_reviews_raw
GROUP BY 
	Hotel_Name,
	Review_Date,
	Reviewer_Nationality,
	Reviewer_Score,
	Tags,
	Positive_Review,
	Negative_Review
HAVING COUNT(*) > 1
-- Result 6 Nov 2026: 
-- 4 groups remain when Tags is added (12 in 6a). These 4 are identical even in the room type
-- and nights: certain duplicates.
-- The 8 groups that disappeared have identical text but different Tags (e.g. Krasnapolsky:
-- party with 2 rooms) = same guest, separate bookings.
-- Decision: use definition 6a (count opinion, not bookings) - see decision log

-- Check 7a: How many different nationalities are there in Amsterdam?
SELECT
    COUNT(DISTINCT Reviewer_Nationality) as number_of_nationalities
FROM dbo.amsterdam_reviews_raw
-- Result 6 Nov 2026: 179 nationalities (NULL not counted).

-- Check 7a-2: Number of nationalities after removing spaces
SELECT
	COUNT(DISTINCT LTRIM(RTRIM(Reviewer_Nationality))) AS number_of_nationalities_trimmed
FROM dbo.amsterdam_reviews_raw
-- Result 6 Nov 2026: 179 after trimming = same as 7a.
-- Spaces do not split any nationality into two groups. Trim anyway in clean table (for Power BI).

-- Check 7b: Which 10 nationalities have the most reviews?
SELECT TOP 10
    Reviewer_Nationality,
    COUNT(*) AS number_of_reviews,
    CAST(COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM dbo.amsterdam_reviews_raw)
        AS DECIMAL(5,2)) AS percentage_of_all_reviews
FROM dbo.amsterdam_reviews_raw
GROUP BY Reviewer_Nationality
ORDER BY number_of_reviews DESC
-- Result 6 Nov 2026: Top 10 = 70.6% of reviews. UK alone: 40.2%, USA 8.4%
-- English speaking markets dominate; Germany only 2.2%, Netherlands 3.0%

-- Check 7c: How many nationalities have fewer than 100 reviews?
SELECT
	Reviewer_Nationality,
	COUNT(*) AS number_of_reviews
FROM dbo.amsterdam_reviews_raw
GROUP BY Reviewer_Nationality
HAVING COUNT(*) < 100
ORDER BY number_of_reviews DESC
-- Result 6 Nov 2026: 124 rows = 123 of 179 nationalities (69%) have fewer than
-- 100 reviews written by guests of that nationality. Plus 69 rows with NULL nationality

-- Check 7d: Nationalities with 500 - 1,000 reviews (to decide the minimum group size)
SELECT
    Reviewer_Nationality,
    COUNT(*) AS reviews_count
FROM dbo.amsterdam_reviews_raw
GROUP BY Reviewer_Nationality
HAVING COUNT(*) BETWEEN 500 AND 1000
ORDER BY reviews_count DESC
-- Result 9 Nov 2026: 8 nationalities, 5, 599 reviews (9.8%):
-- Turkey 936, Saudi Arabia 841, France 762, Switzerland 743, Italy 652,
-- South Africa 616, Russia 530, India 519.
-- Combined with check 7b (top 10, all > 1,000): 18 nationalities with at least 500 reviews
-- = 46,011 reviews (80.4%). Rest: 161 nationalitites + NULL = 11,203 reviews (19.6%).
-- Decision: minimum 500 reviews per nationality, rest = "Other" - see decision log 9 Nov 2026.

-- Check 8: Minimum, maximum and average reviewer score (converted from text to number)
SELECT
	MIN(TRY_CONVERT(DECIMAL(10,2), Reviewer_Score)) as Min_Score,
	MAX(TRY_CONVERT(DECIMAL(10,2), Reviewer_Score)) as Max_Score,
	AVG(TRY_CONVERT(DECIMAL(10,2), Reviewer_Score)) as Avg_Score
FROM dbo.amsterdam_reviews_raw
-- Result 9 Nov 2026: min 2.5, max 10.0, average 8.46
-- Range 2.5 - 10 matches the Booking.com scale - no impossible values
-- Average is high (8.46): scores cluster near the top, so differences between hotels
-- will be small (often tenths of a point)

-- Check 8b: Scores that could not be converted to a number
SELECT
	COUNT(*) AS failed_conversions
FROM dbo.amsterdam_reviews_raw
WHERE TRY_CONVERT(DECIMAL(3,1), Reviewer_Score) IS NULL
-- Result 9 Nov 2026:0 failed conversions
-- all 57,214 scores are valid numbers - check 8 results are complete

-- Check 9: Earliest and latest review date (text converted to date, format 101 = M/D/YYYY)
SELECT 
	MIN(TRY_CONVERT(DATE, Review_Date, 101)) as earliest_date,
	MAX(TRY_CONVERT(DATE, Review_Date, 101)) as latest_date
FROM dbo.amsterdam_reviews_raw
-- Result 9 Nov 2026: earliest review 4 Aug 2015, latest review 3 Aug 2017
-- Exactly two years of data - every month of the year appears twice
-- (August split: 4-31 Aug 2015, Aug 2016, 1-3 Aug 2017)
-- Same result without 101 (SQL Server default = US format), but 101 makes it explicit

-- Check 9a: Dates that could not be converted to a date
SELECT 
	COUNT(*) as failed_conversions
FROM dbo.amsterdam_reviews_raw
WHERE TRY_CONVERT(DATE, Review_Date, 101) IS NULL
-- Result 9 Nov 2026: 0 failed conversions