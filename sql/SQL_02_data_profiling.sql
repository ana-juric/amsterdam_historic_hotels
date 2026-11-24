/* ============================================================
   Project:  Guest experience in historic hotels
   File:     02_data_profiling.sql
   Purpose:  Profile the raw data: missing values, placeholders,
             odd values, duplicates
   Author:   Ana Juric
   Dates:     5 - 6 Nov 2026
   ============================================================ */
  USE hotel_reviews;

  -- Check 1: Missing values in key columns
  -- "Missing" = NULL or empty text ('')
  SELECT
	COUNT(*) AS total_rows,
	SUM(CASE WHEN Hotel_Name IS NULL OR LTRIM(RTRIM(Hotel_Name)) = ''
			THEN 1 ELSE 0 END) AS missing_hotel_name,
	SUM(CASE WHEN Reviewer_Nationality IS NULL OR LTRIM(RTRIM(Reviewer_Nationality)) = ''
			THEN 1 ELSE 0 END) AS missing_nationality,
	SUM(CASE WHEN Reviewer_Score IS NULL OR LTRIM(RTRIM(Reviewer_Score)) = ''
			THEN 1 ELSE 0 END) AS missing_score,
	SUM(CASE WHEN Review_Date IS NULL OR LTRIM(RTRIM(Review_Date)) = ''
			THEN 1 ELSE 0 END) AS missing_date,
	SUM(CASE WHEN lat IS NULL OR LTRIM(RTRIM(lat)) IN ('', 'NA')
			THEN 1 ELSE 0 END) AS missing_lat
FROM dbo.hotel_reviews_raw
-- Result 5 Nov 2026: 
-- total_rows:515738
-- missing_hotel_name: 0 
-- missing_nationality: 523 (0.1% of rows)
-- missing_score: 0
-- missing_date: 0
-- missing_lat: 3268 (0.6% of rows)

-- Check 2: Which hotels have missing coordinates?
SELECT
	Hotel_Name,
	Hotel_Address,
	COUNT(*) AS number_of_reviews
FROM dbo.hotel_reviews_raw
WHERE lat IS NULL 
	OR LTRIM(RTRIM(lat)) IN ('', 'NA')
GROUP BY Hotel_Name, Hotel_Address
ORDER BY number_of_reviews DESC
-- Result 5 Nov 2026: 17 hotels have missing coordinates; none are in Amsterdam. No action needed.

-- Check 3: How many hotels and reviews per country?
SELECT 
    CASE 
        WHEN Hotel_Address LIKE '%Netherlands' THEN 'Amsterdam'
        WHEN Hotel_Address LIKE '%Austria' THEN 'Vienna'
        WHEN Hotel_Address LIKE '%France' THEN 'Paris'
        WHEN Hotel_Address LIKE '%Spain' THEN 'Barcelona'
        WHEN Hotel_Address LIKE '%Italy' THEN 'Milan'
        WHEN Hotel_Address LIKE '%United Kingdom' THEN 'London'
        ELSE 'Other'
    END AS City,
    COUNT(DISTINCT Hotel_Address) AS number_of_addresses,
    COUNT(DISTINCT Hotel_Name) AS number_of_hotels,
    COUNT(*) AS number_of_reviews
FROM dbo.hotel_reviews_raw
GROUP BY 
    CASE 
        WHEN Hotel_Address LIKE '%Netherlands' THEN 'Amsterdam'
        WHEN Hotel_Address LIKE '%Austria' THEN 'Vienna'
        WHEN Hotel_Address LIKE '%France' THEN 'Paris'
        WHEN Hotel_Address LIKE '%Spain' THEN 'Barcelona'
        WHEN Hotel_Address LIKE '%Italy' THEN 'Milan'
        WHEN Hotel_Address LIKE '%United Kingdom' THEN 'London'
        ELSE 'Other'
    END
ORDER BY number_of_reviews DESC;
-- Result 5 Nov 2026: 
-- London: 399 addresses, 400 hotels, 262301 reviews 
-- Barcelona: 211 addresses, 211 hotels, 60149 reviews
-- Paris: 458 addresses, 458 hotels, 59928 reviews
-- Amsterdam: 105 addresses, 105 hotels, 57214 reviews (11% of the dataset)
-- Vienna: 158 addresses, 158 hotels, 38939 reviews
-- Milan: 162 addresses, 162 hotels, 37207 reviews

-- Check 4: Which addresses have more than one hotel name?
SELECT 
	Hotel_Address,
	COUNT(DISTINCT Hotel_Name) AS number_of_names
FROM dbo.hotel_reviews_raw
GROUP BY Hotel_Address
HAVING COUNT(DISTINCT Hotel_Name) > 1
-- Result 6 Nov 2026: 1 address with 2 hotel names. Outside scope – no action.

-- Check 5a: Amsterdam – any hotel name with more than one address?
SELECT 
	Hotel_Name,
	COUNT(DISTINCT Hotel_Address) AS number_of_addresses
FROM dbo.hotel_reviews_raw
WHERE Hotel_Address LIKE '%Netherlands'
GROUP BY Hotel_Name
HAVING COUNT(DISTINCT Hotel_Address) > 1
-- Result 6 Nov 2026: 0 rows - OK

-- Check 5b: Amsterdam – any address with more than one hotel name?
SELECT 
	Hotel_Address,
	COUNT(DISTINCT Hotel_Name) AS number_of_names
FROM dbo.hotel_reviews_raw
WHERE Hotel_Address LIKE '%Netherlands'
GROUP BY Hotel_Address
HAVING COUNT(DISTINCT Hotel_Name) > 1
-- Result 6 Nov 2026: 0 rows - OK

