/* ============================================================
   Project:  Guest experience in historic hotels
   File:     04_data_cleaning.sql
   Purpose:  Create amsterdam_reviews_clean from amsterdam_reviews_raw:
             add review_id, remove duplicates, convert data types,
             trim spaces, replace placeholders with NULL,
             add nationality_group, drop unused columns
   Author:   Ana Juric
   Date:     9 Nov 2026
   ============================================================ */
   USE hotel_reviews;
   
-- Step 1: Create the clean table as a copy of the Amsterdam raw table,
-- with unique review_id for every row
SELECT
    IDENTITY(INT, 1, 1) AS review_id,
    *
INTO dbo.amsterdam_reviews_clean
FROM dbo.amsterdam_reviews_raw;
-- Result 9 Nov 2026: 57,214 rows affected

-- Check 1a: total number of rows 
SELECT COUNT(*) AS total_number_of_rows
FROM dbo.amsterdam_reviews_clean;
-- Result 9 Nov 2026: 57,214 - OK

-- Check 1b: the number of different review_id values
SELECT COUNT(DISTINCT review_id) AS number_of_distinct_review_ids
FROM dbo.amsterdam_reviews_clean;
-- Result 9 Nov 2026: 57,214 - OK

-- Check 1c: the lowest and highest review_id
SELECT
    MIN(review_id) as lowest_review_id, 
    MAX(review_id) as highest_review_id
FROM dbo.amsterdam_reviews_clean;
-- Result 9 Nov 2026: lowest_review_id = 1, highest_review_id = 57214 - OK

-- Step 2a: Preview - how many rows would be deleted as duplicates?
-- Keep the lowest review_id in each duplicate group
SELECT COUNT(*) AS rows_to_delete
FROM dbo.amsterdam_reviews_clean
WHERE review_id NOT IN (
		SELECT MIN (review_id)
		FROM dbo.amsterdam_reviews_clean
		GROUP BY
			Hotel_Name,
			Review_Date,
			Reviewer_Nationality,
			Reviewer_Score,
			Positive_Review,
			Negative_Review
		);
-- Result 9 Nov 2026: 12 duplicate rows

-- Step 2b: Delete duplicate rows (keep the lowest review_id in each group)
DELETE
FROM dbo.amsterdam_reviews_clean
WHERE review_id NOT IN (
        SELECT MIN(review_id)
        FROM dbo.amsterdam_reviews_clean
        GROUP BY
            Hotel_Name,
            Review_Date,
            Reviewer_Nationality,
            Reviewer_Score,
            Positive_Review,
            Negative_Review
      );
-- Result 9 Nov 2026: 12 rows affected

-- Check 2b-1: Confirming the total number of rows
SELECT COUNT(*) AS total_rows
FROM dbo.amsterdam_reviews_clean;
-- Result 9 Nov 2026: 57,202 - OK

-- Check 2b-2: Confirming no duplicates are left
SELECT COUNT(*) AS remaining_duplicates
FROM dbo.amsterdam_reviews_clean
WHERE review_id NOT IN (
		SELECT MIN (review_id)
		FROM dbo.amsterdam_reviews_clean
		GROUP BY
			Hotel_Name,
			Review_Date,
			Reviewer_Nationality,
			Reviewer_Score,
			Positive_Review,
			Negative_Review
		);
-- Result 9 Nov 2026: 0 remaining duplicates - OK

-- Step 3: Convert data types
-- Method: rename old column (_text), add new typed column, fill with TRY_CONVERT, check.
-- See decision log 10 Nov 2026.

-- Step 3a: Rename the old text date column to free the name review_date
EXEC sp_rename 'dbo.amsterdam_reviews_clean.Review_Date', 'review_date_text', 'COLUMN';
-- Result 10 Nov 2026: renamed - OK

-- Step 3a-1: Add a new column for the review date as a real DATE
ALTER TABLE dbo.amsterdam_reviews_clean
ADD review_date DATE;
-- Result 10 Nov 2026: column review_date added - OK

-- Step 3a-2: Fill review_date with the converted text date (format 101 = M/D/YYYY)
UPDATE dbo.amsterdam_reviews_clean
SET review_date = TRY_CONVERT(DATE, review_date_text, 101);
-- Result 10 Nov 2026: 57,202 rows affected - OK

-- Check 3a-3: Is review_date filled in every row?
SELECT COUNT(*) AS empty_review_dates
FROM dbo.amsterdam_reviews_clean
WHERE review_date IS NULL;
-- Result 10 Nov 2026: 0 empty dates - OK

-- Step 3b: Rename the old text score column to free the name reviewer_score
EXEC sp_rename 'dbo.amsterdam_reviews_clean.Reviewer_Score', 'reviewer_score_text', 'COLUMN';
-- Result 10 Nov 2026: renamed - OK

-- Step 3b-1: Add a new column for the reviewer score as DECIMAL(3,1)
ALTER TABLE dbo.amsterdam_reviews_clean
ADD reviewer_score DECIMAL(3,1);
-- Result 10 Nov 2026: column reviewer_score added - OK

-- Step 3b-2: Fill reviewer_score with the converted text score (DECIMAL(3,1) = e.g. 8.3)
UPDATE dbo.amsterdam_reviews_clean
SET reviewer_score = TRY_CONVERT(DECIMAL(3,1), reviewer_score_text);
-- Result 10 Nov 2026: 57,202 rows affected - OK

-- Check 3b-3: Is reviewer_score filled in every row?
SELECT COUNT(*) AS empty_scores
FROM dbo.amsterdam_reviews_clean
WHERE reviewer_score IS NULL;
-- Result 10 Nov 2026: 0 - OK, every row has a score

-- Check 3b-4: Do the converted scores match profiling (Check 8: min 2.5, max 10, avg 8.456)?
SELECT
    MIN(reviewer_score) AS min_score,
    MAX(reviewer_score) AS max_score,
    AVG(reviewer_score) AS avg_score
FROM dbo.amsterdam_reviews_clean;
-- Result 10 Nov 2026: min 2.5, max 10.0, avg 8.456316 - OK
-- Avg differs from profiling (8.456311) only in the 6th decimal: expected,
-- because 12 duplicate rows were removed. No values lost or rounded.

-- Step 3c: Rename the old text average score column to free the name average_score
EXEC sp_rename 'dbo.amsterdam_reviews_clean.Average_Score', 'average_score_text', 'COLUMN';
-- Result 10 Nov 2026: renamed - OK

-- Step 3c-1: Add a new column for the average score as DECIMAL(3,1)
ALTER TABLE dbo.amsterdam_reviews_clean
ADD average_score DECIMAL(3,1);
-- Result 10 Nov 2026: average_score column added - OK

-- Step 3c-2: Fill average_score with the converted text score (DECIMAL(3,1) = e.g. 8.8)
UPDATE dbo.amsterdam_reviews_clean
SET average_score = TRY_CONVERT(DECIMAL(3,1), average_score_text);
-- Result 10 Nov 2026: 57,202 rows affected - OK

-- Check 3c-3: Is average_score filled in every row?
SELECT
	COUNT(*) AS empty_average_score
FROM dbo.amsterdam_reviews_clean
WHERE average_score IS NULL;
-- Result 10 Nov 2026: 0 - OK, every row has a score

-- Check 3c-4: Does every hotel have exactly one average_score (hotel-level column)?
SELECT 
	Hotel_Name,
	COUNT(DISTINCT(average_score)) AS number_of_scores
FROM dbo.amsterdam_reviews_clean
GROUP BY Hotel_Name
HAVING COUNT(DISTINCT(average_score)) > 1;
-- Result 10 Nov 2026: 0 rows - OK, every hotel has exactly one average score

-- Step 3d: Add a new column lat_num as DECIMAL(10,7)
ALTER TABLE dbo.amsterdam_reviews_clean
ADD lat_num DECIMAL(10,7);
-- Result 10 Nov 2026: column lat_num added - OK

-- Step 3d-1: Fill lat_num with the converted text latitude (DECIMAL(10,7) = e.g. 52.3743712)
UPDATE dbo.amsterdam_reviews_clean
SET lat_num = TRY_CONVERT(DECIMAL(10,7), lat);
-- Result 10 Nov 2026: 57,202 rows affected - OK

-- Check 3d-2: Is lat_num filled in every row?
SELECT 
	COUNT(*) AS empty_lat_rows
FROM dbo.amsterdam_reviews_clean
WHERE lat_num IS NULL;
-- Result 10 Nov 2026: 0 - OK, every row has lat

-- Check 3d-3: Is lat_num within Amsterdam's latitude  (about 52.3 to 52.4)?
SELECT 
	MIN(lat_num) as min_lat,
	MAX(lat_num) as max_lat
FROM dbo.amsterdam_reviews_clean;
-- Result 10 Nov 2026: min_lat = 52.2924567, max_lat = 52.4001813 - OK
-- Min slightly below 52.3 = southern edge of Amsterdam (~1 km); palusible

-- Step 3e: Add a new column lng_num as DECIMAL(10,7)
ALTER TABLE dbo.amsterdam_reviews_clean
ADD lng_num DECIMAL(10,7);
-- Result 10 Nov 2026: column lng_num added - OK

-- Step 3e-1: Fill lng_num with the converted text longitude (DECIMAL(10,7) = e.g. 4.8746196)
UPDATE dbo.amsterdam_reviews_clean
SET lng_num = TRY_CONVERT(DECIMAL(10,7), lng);
-- Result 10 Nov 2026: 57,202 rows affected - OK

-- Check 3e-2: Is lng_num filled in every row?
SELECT
	COUNT(*) AS empty_lng_rows
FROM dbo.amsterdam_reviews_clean
WHERE lng_num IS NULL;
-- Result 10 Nov 2026: 0 - OK, every row has lng

-- Check 3e-3: Is lng_num within Amsterdam’s longitude (about 4.7 to 5.0)?
SELECT
	MIN(lng_num) AS min_lng,
	MAX(lng_num) AS max_lng
FROM dbo.amsterdam_reviews_clean;
-- Result 10 Nov 2026: min = 4.8178172, max = 4.9962997 - OK

-- Step 3f: Rename the old text total reviews column to free the name total_number_of_reviews
EXEC sp_rename 'dbo.amsterdam_reviews_clean.Total_Number_of_Reviews', 'total_number_of_reviews_text', 'COLUMN';
-- Result 10 Nov 2026: column renamed - OK

-- Step 3f-1: Add a new column total_number_of_reviews as INT (whole number)
ALTER TABLE dbo.amsterdam_reviews_clean
ADD total_number_of_reviews INT;
-- Result 10 Nov 2026: column total_number_of_reviews added - OK

-- Step 3f-2: Fill total_number_of_reviews column with the converted text count (INT, e.g. 1403)
UPDATE dbo.amsterdam_reviews_clean
SET total_number_of_reviews = TRY_CONVERT(INT, total_number_of_reviews_text);
-- Result 10 Nov 2026: 57,202 rows affected - OK

-- Check 3f-3: Is total_number_of_reviews filled in every row?
SELECT 
	COUNT(*) AS empty_total_reviews
FROM dbo.amsterdam_reviews_clean
WHERE total_number_of_reviews IS NULL;
-- Result 10 Nov 2026: 0 - OK, every row has a number of reviews

-- Check 3f-4: Does every hotel have exactly one total_number_of_reviews (hotel_level_column)?
SELECT
	Hotel_Name,
	COUNT(DISTINCT total_number_of_reviews) AS number_of_values
FROM dbo.amsterdam_reviews_clean
GROUP BY Hotel_Name
HAVING COUNT(DISTINCT total_number_of_reviews) > 1;
-- Result 10 Nov 2026: 0 rows - OK, every hotel has exactly one total number of reviews

-- Check 3f-5: Is total_number_of_reviews in a realistic range?
-- Expected: no negative or zero values (it's a count); hundreds to thousands per hotel
SELECT
    MIN(total_number_of_reviews) AS min_total_reviews,
    MAX(total_number_of_reviews) AS max_total_reviews
FROM dbo.amsterdam_reviews_clean;
-- Result 11 Nov 2026: min = 61, max = 8,177 - OK, no negative or zero values
-- Min lower than expected: plausible for a small hotel. Small hotels may give unreliable results later.

-- Step 3g: Rename the old text column to free the name additional_number_of_scoring
EXEC sp_rename 'dbo.amsterdam_reviews_clean.Additional_Number_of_Scoring', 'additional_number_of_scoring_text', 'COLUMN';
-- Result 10 Nov 2026: column renamed - OK

-- Step 3g-1: Add column additional_number_of_scoring as INT (whole number)
ALTER TABLE dbo.amsterdam_reviews_clean
ADD additional_number_of_scoring INT;
-- Result 10 Nov 2026: column additional_number_of_scoring added - OK

-- Step 3g-2: Fill additional_number_of_scoring with the converted text value (INT, e.g. 62)
UPDATE dbo.amsterdam_reviews_clean
SET additional_number_of_scoring = TRY_CONVERT(INT, additional_number_of_scoring_text);
-- Result 11 Nov 2026: 57,202 rows affected - OK

-- Check 3g-3: Did every value convert? (TRY_CONVERT gives NULL if a value fails)
SELECT
    COUNT(*) AS empty_additional_scoring
FROM dbo.amsterdam_reviews_clean
WHERE additional_number_of_scoring IS NULL;
-- Result 11 Nov 2026: 0 - OK, every value converted, no failures

-- Check 3g-4: Does every hotel have exactly one additional_number_of_scoring (hotel-level column)?
SELECT
    Hotel_Name,
    COUNT(DISTINCT additional_number_of_scoring) AS distinct_additional_scoring
FROM dbo.amsterdam_reviews_clean
GROUP BY Hotel_Name
HAVING COUNT(DISTINCT additional_number_of_scoring) > 1;
-- Result 11 Nov 2026: 0 rows - OK, every hotel has exactly one value

-- Check 3g-5: Is additional_number_of_scoring in a realistic range?
-- Expected: no negative values (it's a count); hundreds per hotel, similar in size to Total_Number_of_Reviews
SELECT
	MIN(additional_number_of_scoring) AS min_additional_scoring,
	MAX(additional_number_of_scoring) AS max_additional_scoring
FROM dbo.amsterdam_reviews_clean;
-- Result 11 Nov 2026: min = 18, max = 975 - OK, no negative or zero values, realistic range

-- Step 3h: add column reviews_given_by_reviewer as INT (whole number = e.g.16)
ALTER TABLE dbo.amsterdam_reviews_clean
ADD reviews_given_by_reviewer INT;
-- Result 11 Nov 2026: column reviews_given_by_reviewer added - OK

-- Step 3h-1: Fill reviews_given_by_reviewer with the converted text value (INT, e.g. 16)
UPDATE dbo.amsterdam_reviews_clean
SET reviews_given_by_reviewer = TRY_CONVERT(INT, Total_Number_of_Reviews_Reviewer_Has_Given);
-- Result 11 Nov 2026: 57,202 rows affected - OK

-- Check 3h-2: Did every value convert?
-- Expected: 0
SELECT
	COUNT(*) AS failed_conversions
FROM dbo.amsterdam_reviews_clean
WHERE reviews_given_by_reviewer IS NULL;
-- Result 11 Nov 2026: 0 - OK, every value converted, no failures

-- Check 3h-3: Is reviews_given_by_reviewer in a realistic range?
-- Expected: minimum 1 (the current review counts); most reviewers low, a few frequent reviewers with hundreds
SELECT
	MIN(reviews_given_by_reviewer) AS min_reviews,
	MAX(reviews_given_by_reviewer) AS max_reviews
FROM dbo.amsterdam_reviews_clean;
-- Result 11 Nov 2026: min = 1, max = 281 - OK, matches expectation; 281 is plausible for a frequent traveller

-- Check 4a-1: Before trim - how many Reviewer_Nationality values start or end with a space?
-- Expected: thousands 
SELECT
	COUNT(*) AS rows_with_extra_spaces
FROM dbo.amsterdam_reviews_clean
WHERE Reviewer_Nationality LIKE ' %'
	OR Reviewer_Nationality LIKE '% ';
-- Result 11 Nov 2026: 57,133 of 57,202 rows - more than expected: almost every value has extra spaces.
-- The other 69 rows are the NULL nationalities (see decision log 9 Nov): NULL has no text, so it can't match LIKE.

-- Check 4a-2: Before trim - how many Hotel_Name values start or end with a space?
-- Expected: 0 or hundreds (hotel-level column, so a problem affects all reviews of a hotel)
SELECT
	COUNT(*) AS rows_with_extra_spaces
FROM dbo.amsterdam_reviews_clean
WHERE Hotel_Name LIKE ' %'
	OR Hotel_Name LIKE '% ';
-- Result 11 Nov 2026: 0 - no extra spaces in hotel names. Trim anyway, as a safety step (no effect).

-- Check 4a-3: Before trim - how many Hotel_Address values start or end with a space?
-- Expected: 0 or hundreds (hotel-level column, so a problem affects all reviews of a hotel)
SELECT
	COUNT(*) AS rows_with_extra_spaces
FROM dbo.amsterdam_reviews_clean
WHERE Hotel_Address LIKE ' %'
	OR Hotel_Address LIKE '% ';
-- Result 11 Nov 2026: 0 - matches expectation, no extra spaces in hotel addresses. Trim anyway, as a safety step (no effect).

-- Check 4a-4: Before trim - how many Negative_Review values start or end with a space?
-- Expected: thousands (review-level column, so each review can differ)
SELECT 
	COUNT(*) AS rows_with_extra_spaces
FROM dbo.amsterdam_reviews_clean
WHERE Negative_Review LIKE ' %'
	OR Negative_Review LIKE '% ';
-- Result 11 Nov 2026: 25,384 of 57,202 rows (44%) - matches expectation

-- Check 4a-5: Before trim - how many Positive_Review values start or end with a space?
-- Expected: thousands (review-level column, so each review can differ)
SELECT 
	COUNT(*) AS rows_with_extra_spaces
FROM dbo.amsterdam_reviews_clean
WHERE Positive_Review LIKE ' %'
	OR Positive_Review LIKE '% ';
-- Result 11 Nov 2026: 31,046 of 57,202 rows (54%) - matches expectation

-- Check 4a-6: Before trim - how many Tags values start or end with a space?
-- Expected: 0 (values start with "[" and end with "]")
SELECT 
	COUNT(*) AS rows_with_extra_spaces
FROM dbo.amsterdam_reviews_clean
WHERE Tags LIKE ' %'
	OR Tags LIKE '% ';
-- Result 11 Nov 2026: 0 - matches expectation. Trim anyway, as a safety step (no effect).
-- Note: spaces INSIDE the tags (e.g. ' Couple ') remain; TRIM only affects the start and end of the whole value.

-- Step 4b: Trim leading and trailing spaces in all 6 text columns
-- Expected: 57,202 rows affected (no WHERE, so every row is updated, even where nothing changes)
UPDATE dbo.amsterdam_reviews_clean
SET
	Hotel_Address = TRIM(Hotel_Address),
	Hotel_Name = TRIM(Hotel_Name),
	Reviewer_Nationality = TRIM(Reviewer_Nationality),
	Negative_Review = TRIM(Negative_Review),
	Positive_Review = TRIM(Positive_Review),
	Tags = TRIM(Tags);
-- Result 11 Nov 2026: 57,202 rows affected - OK, matches expectation.

-- Check 4c: After trim - how many rows still have a space at the start or end of any text column?
-- Expected: 0
SELECT
	COUNT(*) AS rows_with_extra_spaces
FROM dbo.amsterdam_reviews_clean
WHERE Hotel_Address LIKE ' %' OR Hotel_Address LIKE '% '
	OR Hotel_Name LIKE ' %' OR Hotel_Name LIKE '% '
	OR Reviewer_Nationality LIKE ' %' OR Reviewer_Nationality LIKE '% '
	OR Negative_Review LIKE ' %' OR Negative_Review LIKE '% '
	OR Positive_Review LIKE ' %' OR Positive_Review LIKE '% '
	OR Tags LIKE ' %' OR Tags LIKE '% '
-- Result 11 Nov 2026: 0 - OK, matches expectation. Before trim: nationality 57,133, negative 25,384, positive 31,046 rows.

-- Step 5: Replace placeholders with NULL
-- Check 5a-1: Before - how many rows have Negative_Review equal to 'No Negative'?
-- Expected: up to 31,818 (rows without extra spaces in Check 4a-4), if the placeholders were the rows without spaces
SELECT
	COUNT(*) AS no_negative_rows
FROM dbo.amsterdam_reviews_clean
WHERE Negative_Review = 'No Negative';
-- Result 11 Nov 2026: 14,270 of 57,202 rows (25%) - lower than expected.
-- Spaces don't identify placeholders: about 17,500 real reviews also had no extra spaces.

-- Check 5a-2: Before - how many rows have Positive_Review equal to 'No Positive'?
-- Expected: fewer than 'No Negative' (14,270), because most guests are satisfied (average score 8.46)
SELECT
	COUNT(*) AS no_positive_rows
FROM dbo.amsterdam_reviews_clean
WHERE Positive_Review = 'No Positive';
-- Result 11 Nov 2026: 3,812 of 57,202 rows (6.7%) - matches expectation.
-- 25% of guests wrote nothing negative, only 6.7% nothing positive.

-- Step 5b-1: Replace 'No Negative' with NULL
-- Expected: 14,270 rows affected (see Check 5a-1)
UPDATE dbo.amsterdam_reviews_clean
SET Negative_Review = NULL
WHERE Negative_Review = 'No Negative';
-- Result: 14270 rows affected - matches expectation

-- Step 5b-2: Replace 'No Positive' with NULL
-- Expected: 3,812 rows affected (see Check 5a-2)
UPDATE dbo.amsterdam_reviews_clean
SET Positive_Review = NULL
WHERE Positive_Review = 'No Positive';
-- Result 11 Nov 2026: 3,812 rows affected - matches expectation

-- Check 5c-1: After - how many rows still have 'No Negative' or 'No Positive'?
-- Expected: 0
SELECT
	COUNT(*) AS remaining_placeholders
FROM dbo.amsterdam_reviews_clean
WHERE Negative_Review = 'No Negative' 
	OR Positive_Review = 'No Positive';
-- Result 11 Nov 2026: 0 - matches expectation

-- Check 5c-2a: Before - how many NULLs did the review columns have in the raw table?
-- Expected: a small number (empty reviews in the source); may include 1-2 from the 12 duplicates
SELECT 
	SUM(CASE WHEN Negative_Review IS NULL THEN 1 ELSE 0 END) AS negative_nulls,
	SUM(CASE WHEN Positive_Review IS NULL THEN 1 ELSE 0 END) AS positive_nulls
FROM dbo.amsterdam_reviews_raw;
-- Result: negative nulls = 91, positive nulls = 16 - matches expectation
-- Note: not checked during profiling; checked here instead.

-- Check 5c-2: After - did the NULLs go up by the right amount?
-- Expected: Negative_Review = 91 (see Check 5c-2a) + 14,270 = 14,361; Positive_Review = 16 + 3,812 = 3,828
SELECT 
	SUM(CASE WHEN Negative_Review IS NULL THEN 1 ELSE 0 END) AS negative_nulls,
	SUM(CASE WHEN Positive_Review IS NULL THEN 1 ELSE 0 END) AS positive_nulls
FROM dbo.amsterdam_reviews_clean;
-- Result 11 Nov 2026: negative nulls = 14,361 - matches, positive nulls = 3,827 - 1 fewer than expected.
-- Most likely reason: one of the 12 removed duplicates had an empty positive review.

-- Step 6a: Which nationalities have at least 500 reviews in the clean table?
-- Expected: 18 (Checks 7b and 7d in profiling)
SELECT
	Reviewer_Nationality,
	COUNT(*) AS reviews_per_nationality
FROM dbo.amsterdam_reviews_clean
GROUP BY Reviewer_Nationality
HAVING COUNT(*) >= 500
ORDER BY reviews_per_nationality DESC;
-- Result 11 Nov 2026: 18 nationalities - matches expectation. Smallest: India with 519 reviews

-- Step 6b: Add the column nationality_group as NVARCHAR(50) (text, e.g. 'United Kingdom', 'Other')
ALTER TABLE dbo.amsterdam_reviews_clean
ADD nationality_group NVARCHAR(50);
-- Result 11 Nov 2026: column nationality_group added - OK

-- Step 6c: Fill the column nationality_group with 18 nationalities, "Other", "Unknown"
-- Expected: 57,202 rows affected (no WHERE, so every row gets a group)
UPDATE dbo.amsterdam_reviews_clean
SET nationality_group = CASE 
	WHEN Reviewer_Nationality IS NULL THEN 'Unknown'
	WHEN Reviewer_Nationality IN (
		'United Kingdom',
		'United States of America',
		'Ireland',
		'Australia',
		'Netherlands',
		'Germany',
		'Israel',
		'Canada',
		'United Arab Emirates',
		'Belgium',
		'Turkey',
		'Saudi Arabia',
		'France',
		'Switzerland',
		'Italy',
		'South Africa',
		'Russia',
		'India'
		) THEN Reviewer_Nationality
		ELSE 'Other'
		END;
-- Result 11 Nov 2026: 57202 rows affected - matches expectation

-- Check 6d: Did every row get the right group?
-- Expected: 20 groups (18 nationalities + 'Other' + 'Unknown'); 'Unknown' = 69 reviews;
--           'Other' = about 20% of reviews (decision log 9 Nov 2026: 80% are in the 18 nationalities)
SELECT
	nationality_group,
	COUNT(*) AS reviews_per_group
FROM dbo.amsterdam_reviews_clean
GROUP BY nationality_group
ORDER BY number_of_groups DESC;
-- Result 11 Nov 2026: 20 groups, Unknown = 69 reviews, Other = 11,132 (19.5%) - matches expectation
-- All groups add up to 57,202. Small differences from profiling (Other - 2, Saudi Arabia - 1, Russia - 1)
-- come from the 12 removed duplicates.

-- Step 7: Drop old and unused columns from amsterdam_reviews_clean
-- 8 old versions replaced by converted columns (Step 3) + 3 unused columns (decision log 5 Nov).
-- See decision log 12 Nov 2026
-- Expected: 11 columns dropped, 16 remain
ALTER TABLE dbo.amsterdam_reviews_clean
DROP COLUMN
	review_date_text, 
	reviewer_score_text, 
	average_score_text, 
	total_number_of_reviews_text, 
	additional_number_of_scoring_text,
	Total_Number_of_Reviews_Reviewer_Has_Given, 
	lat, 
	lng,
	Review_Total_Negative_Word_Counts, 
	Review_Total_Positive_Word_Counts, 
	days_since_review;
-- Result 12 Nov 2026: columns dropped - OK

-- Check 7a: Did the number of rows stay the same?
-- Expected: 57,202 rows (droping columns never removes rows)
SELECT 
	COUNT(*) AS number_of_rows
FROM dbo.amsterdam_reviews_clean
-- Result 12 Nov 2026: 57,202 rows - matches expectation

-- Check 7a-1: Which columns remain, and with which data types?
-- Expected: 16 columns, each in one version only
SELECT
	COLUMN_NAME,
	DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'amsterdam_reviews_clean'
ORDER BY ORDINAL_POSITION;
-- Result 12 Nov 2026: 16 columns - matches expectation
-- int: review_id, total_number_of_reviews, additional_number_of_scoring, reviews_given_by_reviewer
-- decimal: reviewer_score, average_score, lat_num, lng_num
-- date: review_date
-- nvarchar: Hotel_Name, Hotel_Address, Reviewer_Nationality, nationality_group,
--           Positive_Review, Negative_Review, Tags

-- Step 7b: Rename the 6 remaining capitalised columns to lowercase
-- Reason: one consistent naming style in the clean table (see decision log 12 Nov 2026)
-- Expected: 6 columns renamed
EXEC sp_rename 'dbo.amsterdam_reviews_clean.Hotel_Name', 'hotel_name', 'COLUMN';
EXEC sp_rename 'dbo.amsterdam_reviews_clean.Hotel_Address', 'hotel_address', 'COLUMN';
EXEC sp_rename 'dbo.amsterdam_reviews_clean.Reviewer_Nationality', 'reviewer_nationality', 'COLUMN';
EXEC sp_rename 'dbo.amsterdam_reviews_clean.Positive_Review', 'positive_review', 'COLUMN';
EXEC sp_rename 'dbo.amsterdam_reviews_clean.Negative_Review', 'negative_review', 'COLUMN';
EXEC sp_rename 'dbo.amsterdam_reviews_clean.Tags', 'tags', 'COLUMN';
-- Result 12 Nov 2026: 6 columns renamed - OK

-- Check 7b-1: Are all 16 column names now lowercase?
-- Expected: 16 columns, all lowercase
SELECT
	COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'amsterdam_reviews_clean'
ORDER BY ORDINAL_POSITION;
-- Result 12 Nov 2026: 16 columns, all lowercase - matches expectation

-- Step 8a: Final validation of amsterdam_reviews_clean
-- Tests: 57,202 rows; 57,202 different review_ids; 0 NULLs in converted columns
--		  (review_date, reviewer_score, average_score, lat_num, lng_num) and nationality_group;
--		  0 remaining placeholders ("No Negative" / "No Positive")
-- Info: NULLs in review texts should be slightly more than the placeholders counted 
--		 before Step 5 (14,270 "No Negative", 3,812 "No Positive"), because some texts
--		 were already NULL; 69 NULL nationalities (= 'Unknown' group)
SELECT
	COUNT(*) AS number_of_rows,
	COUNT(DISTINCT review_id) AS number_of_review_id,
	SUM(CASE WHEN review_date IS NULL THEN 1 ELSE 0 END) AS review_date_nulls,
	SUM(CASE WHEN reviewer_score IS NULL THEN 1 ELSE 0 END) AS reviewer_score_nulls,
	SUM(CASE WHEN average_score IS NULL THEN 1 ELSE 0 END) AS average_score_nulls,
	SUM(CASE WHEN lat_num IS NULL THEN 1 ELSE 0 END) AS lat_nulls,
	SUM(CASE WHEN lng_num IS NULL THEN 1 ELSE 0 END) AS lng_nulls,
	SUM(CASE WHEN nationality_group IS NULL THEN 1 ELSE 0 END) AS nationality_group_nulls,
	SUM(CASE 
		WHEN positive_review = 'No Positive'
		OR negative_review = 'No Negative'
		THEN 1 ELSE 0
		END) AS number_of_placeholders,
	SUM(CASE WHEN negative_review IS NULL THEN 1 ELSE 0 END) AS info_negative_nulls,
	SUM(CASE WHEN positive_review IS NULL THEN 1 ELSE 0 END) AS info_positive_nulls,
	SUM(CASE WHEN reviewer_nationality IS NULL THEN 1 ELSE 0 END) AS info_nationality_nulls
FROM dbo.amsterdam_reviews_clean
-- Result 12 Nov 2026: 
-- Tests - all match expectation:
-- 57,202 rows; 57,202 different review_ids
-- 0 NULLs in review_date, reviewer_score, average_score, lat_num, lng_num, nationality_group
-- 0 remaining placeholders
-- Info:
--   negative_review NULL: 14,361 (25.1%) = 14,270 placeholders replaced + 91 already NULL
--   positive_review NULL:  3,827 (6.7%)  =  3,812 placeholders replaced + 15 already NULL
--   reviewer_nationality NULL: 69 = 'Unknown' group
-- Conclusion: clean table validated and ready for analysis.






	
