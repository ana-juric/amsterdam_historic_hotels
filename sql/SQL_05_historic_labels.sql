/* ============================================================
  Project:  Guest experience in historic hotels
   File:     05_historic_labels.sql
   Purpose:  Create a hotel-level table, label each hotel as
             historic / other, and bring the labels into SQL
   Author:   Ana Juric
   Date:     12-16 Nov 2026
   ============================================================ */

USE hotel_reviews;

-- Steps 1-2 of Stage 3 (definition and method) have no SQL:
-- see historic_hotels_definition.md and the decision log, 12 Nov 2026.

-- Step 3: Create a hotel table: one row per Amsterdam hotel
-- Reason: "historic" describes a hotel, not a review, so labels are made at hotel level
-- Expected: 105 rows; reviews_in_dataset adds up to 57,202
SELECT
	hotel_name,
	hotel_address,
	average_score,
	total_number_of_reviews,
	lat_num,
	lng_num,
	COUNT(*) AS reviews_in_dataset
INTO dbo.amsterdam_hotels
FROM dbo.amsterdam_reviews_clean
GROUP BY 
	hotel_name,
    hotel_address,
    average_score,
    total_number_of_reviews,
    lat_num,
    lng_num;
-- Result 12 Nov 2026: 105 rows affected - matches expectation

-- Check 3a: Does the hotel table have one row per hotel, and are all reviews included?
-- Expected: 105 hotels; reviews_in_dataset adds up to 57,202 (all reviews in the clean table)
SELECT
	COUNT(*) AS number_of_hotels,
	SUM(reviews_in_dataset) AS total_reviews
FROM dbo.amsterdam_hotels
-- Result 12 Nov 2026: 105 hotels, 57,202 total reviews - matches expectation

-- Step 4: label each hotel as historic or other (no SQL)
-- Done in Excel: docs/historic_lables.xlsx, 12-13 Nov 2026
-- Method: pass 1 (postcode guess) set research order; each hotel then checked against
-- the definition in historic_hotels_definition.md, using official hotel websites
-- and the Amsterdam monument map / national monument register.
-- Evidence, source, check date and notes recorded per hotel in the Excel file.
-- Rules added during labelling (criterion 1 = listed or built 1917 or earlier;
-- building where guests stay; accepted sources; ensemble listings):
-- see decision log, 13-14 Nov 2026.

-- Step 5: Check the labels (no SQL)
-- Checks in Excel, 16 Nov 2026: 105 hotels, no duplicates, no empty labels,
-- label consistent with criteria_met, hotel names identical to dbo.amsterdam_hotels.
-- Result: 49 historic, 56 other.

-- Step 6: Import final historic labels
-- Source file: data/clean/historic_labels_final.txt (Unicode text, tab-separated;
-- exported from historic_labels_final.xlsx: hotel_name, label, criteria_met)
-- Method: SSMS Import Flat File into dbo.historic_labels_raw
-- (all nvarchar; hotel_name 255, label 50, criteria_met 50; no nulls allowed)
-- Expected: 105 rows (49 historic, 56 other)

-- Check 6a: Were all hotels imported?
-- Expected: 105 rows
SELECT
	COUNT(*) AS number_of_historic_hotels
FROM dbo.historic_labels_raw;
-- Result 16 Nov 2026: 105 - matches expectation

-- Check 6b: Which label values exist, and how many hotels has each?
-- Reason: GROUP BY shows every value, also unexpected ones (typos, capitals, spaces)
-- Expected: exactly two values: historic 49, other 56
SELECT
	label,
	COUNT(*) AS number_of_hotels
FROM dbo.historic_labels_raw
GROUP BY label;
-- Result: 49 historic, 56 other - matches expectation

-- Check 6c: How many hotels in amsterdam_hotels have a label?
-- Reason: the labels are linked to hotels by hotel_name (the join key);
-- a hotel whose name doesn't match exactly would lose its label
-- Expected: 0
SELECT
	COUNT(*) AS hotels_without_label
FROM dbo.amsterdam_hotels
WHERE hotel_name NOT IN (
	SELECT hotel_name
	FROM historic_labels_raw
);
-- Result 16 Nov 2026: 0 - matches expectation

-- No reverse check needed: both tables have 105 unique names and all 105 hotels matched,
-- so no label is left without a hotel.

-- Step 7: Add the historic labels to the hotel table
-- Step 7a: Add two empty columns for the label and the criteria
-- Reason: "historic" describes a hotel, so the label belongs in the hotel-level table
-- Types: nvarchar(20) for both (longest values: 'historic' = 8, '1, 2, 3, 5' = 10, plus margin)
-- Columns allow NULL for now: existing rows have no value until step 7b fills them
-- Expected: command completes; amsterdam_hotels has 2 new columns, all values NULL
ALTER TABLE dbo.amsterdam_hotels
ADD label nvarchar(20),
	criteria_met nvarchar(20);
-- Result 16 Nov 2026: command completed; checked with SELECT * FROM dbo.amsterdam_hotels:
-- label and criteria_met added, NULL for all 105 hotels - matches expectation

-- Note 16 Nov 2026: the column was first created as 'labels' by mistake and renamed:
-- EXEC sp_rename 'dbo.amsterdam_hotels.labels', 'label', 'COLUMN';
-- The first rename attempt failed (Msg 15248) because the query window was connected
--   to another database; it worked after running USE hotel_reviews.
-- Checked with INFORMATION_SCHEMA.COLUMNS: column is now 'label', nvarchar(20).
-- (Rename kept as a comment: step 7a above now creates the correct name.)

-- Step 7b: Fill the new columns with the label and criteria of each hotel
-- Reason: copy the checked labels from the import table into the hotel table,
-- matched on hotel_name (join key verified in Check 6c: all 105 hotels match)
-- Expected: 105 rows affected
UPDATE ah
SET 
	ah.label = hl.label,
	ah.criteria_met = hl.criteria_met
FROM dbo.amsterdam_hotels AS ah
JOIN dbo.historic_labels_raw AS hl
ON ah.hotel_name = hl.hotel_name;
-- Result 16 Nov 2026: 105 rows affected - matches expectation

-- Check 7c: Hotels and reviews per label
-- Reason: confirm every hotel has a label (no NULL group), the label counts are right,
-- and see how many reviews each group has (the analysis counts reviews, not hotels)
-- Expected: two rows only: historic 49 hotels, other 56 hotels; no NULL row;
-- reviews in both rows add up to 57,202
SELECT
	label,
	COUNT(*) AS number_of_hotels,
	SUM(reviews_in_dataset) AS number_of_reviews
FROM dbo.amsterdam_hotels
GROUP BY label;
-- Result 16 Nov 2026: historic 49 hotels, 23,962 reviews; other 56 hotels, 33,240 reviews;
-- no NULL row; 23,962 + 33,240 = 57,202 - matches expectation