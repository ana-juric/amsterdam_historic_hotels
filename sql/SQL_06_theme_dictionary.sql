/* ============================================================
   Project:  Guest experience in historic hotels
   File:     06_theme_dictionary.sql
   Purpose:  Import the theme dictionary (one keyword per row) and
             test each theme's keywords on review text before
             freezing dictionary version 1.0
   Author:   Ana Juric
   Date:     16-17 Nov 2026
   ============================================================ */
USE hotel_reviews;

-- Step 1: Import the theme keywords (one keyword per row)
-- Source file: data/clean/theme_keywords_v0.4.txt (Unicode text, tab-separated;
-- made with Power Query from docs/theme_dictionary_v0.4.xlsx: keywords split into rows, trimmed)
-- Method: SSMS Import Flat File into dbo.theme_keywords_raw
-- (theme_id nvarchar(10), keyword nvarchar(100); no nulls allowed)
-- Expected: 308 rows; 16 themes

-- Check 1a: Were all keywords of every theme imported?
-- Reason: a per-theme count shows if one theme is missing or incomplete,
-- which a total count alone could hide
-- Expected (from theme_dictionary_v0.4.xlsx): 16 rows:
--   H1 23, H2 17, H3 22, H4 17, H5 18, H6 18, H7 14,
--   G1 20, G2 23, G3 32, G4 17, G5 20, G6 16, G7 12, G8 12, G9 27 (total 308)
SELECT
	theme_id,
	COUNT(*) AS number_of_keywords
FROM dbo.theme_keywords_raw
GROUP BY theme_id
ORDER BY theme_id;
-- Result 16 Nov 2026: 16 themes, 308 keywords; every theme matches the expected count

-- Step 2: How many reviews contain each keyword in the positive text?
-- Reason: find keywords with 0 matches (typos, unused words) and very high counts (too general)
-- LEFT JOIN keeps all 308 keywords, also those without any match;
-- COUNT(r.review_id) counts only real matches, so unmatched keywords show 0
-- Expected: 308 rows (one per keyword)
SELECT
	k.theme_id,
	k.keyword,
	COUNT(r.review_id) AS positive_matches
FROM dbo.theme_keywords_raw AS k
LEFT JOIN dbo.amsterdam_reviews_clean AS r
	ON r.positive_review LIKE '%' + k.keyword + '%'
GROUP BY
	k.theme_id,
	k.keyword
ORDER BY
	k.theme_id,
	positive_matches DESC;

-- Check 2a: Does the review text contain hyphens at all?
-- Reason: all 8 keywords with a hyphen (check-in, wi-fi, one-of-a-kind...) have 0 matches,
-- while their versions without a hyphen do match; hypothesis: the dataset creator
-- removed punctuation (also seen in hotel names: 'Amr th', 'M venpick')
-- Expected: 0 if the hypothesis is true
SELECT
	COUNT(*) AS reviews_with_hypen
FROM dbo.amsterdam_reviews_clean
WHERE positive_review LIKE '%-%'
-- Result 16 Nov 2026: 0 - hypothesis confirmed: the review text contains no hyphens
-- (punctuation removed by the dataset creator); keywords with hyphens can never match

-- Check 2b: Where do the 'boutique' matches come from?
-- Reason: two hotel names contain 'Boutique' (Apollofirst Boutique Hotel,
-- Boutique Hotel Notting Hill); if most matches come from these hotels,
-- the keyword counts hotel names, not guests describing a type of hotel
-- Expected: if it's a name trap, these two hotels at the top with most of the 207 matches
SELECT
	hotel_name,
	COUNT(*) AS boutique_matches
FROM dbo.amsterdam_reviews_clean
WHERE positive_review LIKE '%boutique%'
GROUP BY hotel_name
ORDER BY boutique_matches DESC;
-- Result 16 Nov 2026: top hotels: Hotel Esther a 34, Hotel JL No76 18, Ambassade Hotel 13,
-- Sir Albert Hotel 13, The Toren 11; Boutique Hotel Notting Hill 6th with 10.
-- Not a name trap: guests use 'boutique' to describe the hotel type; top 5 are all historic.

-- Check 2c: Which hotels get the 'unique' matches?
-- Reason: 'unique' (223 positive matches) may not be specific to historic hotels;
-- the check_words note warns it is also used for modern design hotels
-- Expected: if mainly historic hotels at the top, 'unique' is heritage-related;
-- if modern hotels also appear, H7 must be interpreted through the historic vs other comparison
SELECT
	hotel_name,
	COUNT(*) AS unique_matches
FROM dbo.amsterdam_reviews_clean
WHERE positive_review LIKE '%unique%'
GROUP BY hotel_name
ORDER BY unique_matches DESC;
-- Result 16 Nov 2026: top 5: Fletcher Hotel Amsterdam 23 (other), Hotel Esther a 22 (historic),
-- The Student Hotel Amsterdam City 19 (other), citizenM Amsterdam 18 (other), Ambassade Hotel 12 (historic).
-- 3 of the top 5 are modern hotels: 'unique' is also used for distinctive modern design;
-- keep the keyword, interpret H7 via the historic vs other comparison

-- Check 2d: How many 'unique' matches describe the location?
-- Reason: 'unique location' is location praise (G3), not distinctiveness of the hotel (H7)
-- Expected: if large compared with 223, 'unique' needs an exclusion; if small, keep it
SELECT
	COUNT(*) AS unique_location_matches
FROM dbo.amsterdam_reviews_clean
WHERE positive_review LIKE '%unique location%';
-- Result 16 Nov 2026: 2 of 223 'unique' matches (<1%) - location effect negligible; keep 'unique'

-- Step 3: How many reviews contain each keyword in the negative text?
-- Reason: the research question also asks what guests criticise;
-- find keywords with 0 matches and very high counts in negative text
-- Same query as Step 2, with negative_review instead of positive_review
-- LEFT JOIN keeps all 308 keywords (keywords table on the LEFT);
-- COUNT(r.review_id) counts only real matches, so unmatched keywords show 0
-- Expected: 308 rows (one per keyword); no NULL row
SELECT
	k.theme_id,
	k.keyword,
	COUNT(r.review_id) AS negative_matches
FROM dbo.theme_keywords_raw AS k
LEFT JOIN dbo.amsterdam_reviews_clean AS r
	ON r.negative_review LIKE '%' + k.keyword + '%'
GROUP BY
	k.theme_id,
	k.keyword
ORDER BY
	k.theme_id,
	negative_matches DESC;
-- Result 16 Nov 2026: 308 rows, no NULL row - matches expectation

-- Step 5a: Read a random sample of H1 matches (positive text)
-- Reason: counts show how often a keyword matches; only reading shows if it means the right thing
-- Method: 20 random reviews whose positive text contains at least one H1 keyword
-- Expected: most of the 20 really talk about the building
SELECT TOP 20
	r.hotel_name,
	r.positive_review
FROM dbo.amsterdam_reviews_clean AS r
WHERE EXISTS (
	SELECT 1
	FROM dbo.theme_keywords_raw AS k
	WHERE k.theme_id = 'H1'
		AND r.positive_review LIKE '%' + k.keyword + '%'
)
ORDER BY NEWID();
-- Result 16 Nov 2026: 17 of 20 correct (85%); errors: modern architecture, neighbouring building,
-- hotel name 'Banks Mansion'; see keyword_test_log

-- Step 5b: Read a random sample of H3 matches (positive text)
-- Reason: H3 contains 'historic' and 'history', which may describe the location
-- ('historic centre') instead of the hotel's own history
-- Method: 20 random reviews whose positive text contains at least one H3 keyword
-- Expected: most of the 20 talk about the history or story of the hotel itself
SELECT TOP 20
	r.hotel_name,
	r.positive_review
FROM dbo.amsterdam_reviews_clean AS r
WHERE EXISTS (
	SELECT 1
	FROM dbo.theme_keywords_raw AS k
	WHERE k.theme_id = 'H3'
		AND r.positive_review LIKE '%' + k.keyword + '%'
)
ORDER BY NEWID();
-- Result 16 Nov 2026: 12 of 20 correct (60%); errors from 'years old' (2), 'famous' (2),
-- 'century' (2), location (1), 'lovestory' (1); see keyword_test_log

-- Step 5c: Read a random sample of H2 matches (positive text)
-- Reason: check that H2 keywords match original or period features, not modern ones;
-- check_words to watch: tiles (modern bathrooms), wooden floor (noise), artwork (modern art hotels)
-- Method: 20 random reviews whose positive text contains at least one H2 keyword
-- Expected: most of the 20 describe original or period elements (beams, antiques, Delft tiles...)
SELECT TOP 20
	r.hotel_name,
	r.positive_review
FROM dbo.amsterdam_reviews_clean AS r
WHERE EXISTS (
	SELECT 1
	FROM dbo.theme_keywords_raw AS k
	WHERE k.theme_id = 'H2'
	  AND r.positive_review LIKE '%' + k.keyword + '%'
)
ORDER BY NEWID();
-- Result 17 Nov 2026: 4 of 20 correct (20%); errors from 'fireplace' (8, of which 7 Urban Lodge),
-- 'artwork' (6), 'tiles' (1, inside the typo 'detiles'), 'paintings' (1, modern);
-- fix: remove fireplace, artwork, art collection, tiles; re-test after the fix;
-- see keyword_test_log

-- Step 5d: Read a random sample of H4 matches (positive text)
-- Reason: H4 is the noisiest theme; check that keywords describe a feeling of the past,
-- not general atmosphere; check_words to watch: character, authentic
-- Method: 20 random reviews whose positive text contains at least one H4 keyword
-- Expected: most of the 20 describe a feeling linked to the past or the historic setting
SELECT TOP 20
	r.hotel_name,
	r.positive_review
FROM dbo.amsterdam_reviews_clean AS r
WHERE EXISTS (
	SELECT 1
	FROM dbo.theme_keywords_raw AS k
	WHERE k.theme_id = 'H4'
	  AND r.positive_review LIKE '%' + k.keyword + '%'
)
ORDER BY NEWID();
-- Result 17 Nov 2026: 9 of 20 correct (45%); 'character' matched 13, only 3 correct;
-- other errors: 'old world charm' about the city (1); fix: remove 'character';
-- estimated ~86% after fix; see keyword_test_log

-- Step 5e: Read a random sample of H5 matches (positive text)
-- Reason: check that H5 keywords link the hotel to Dutch or Amsterdam culture, not to
-- food, stairs or location; check_words to watch: typical Dutch, Dutch style
-- (also breakfast, stairs), old Amsterdam (also location), like a local (neighbourhood)
-- Method: 20 random reviews whose positive text contains at least one H5 keyword
-- Expected: most of the 20 describe the hotel as typically Dutch or Amsterdam
SELECT TOP 20
	r.hotel_name,
	r.positive_review
FROM dbo.amsterdam_reviews_clean AS r
WHERE EXISTS (
	SELECT 1
	FROM dbo.theme_keywords_raw AS k
	WHERE k.theme_id = 'H5'
	  AND r.positive_review LIKE '%' + k.keyword + '%'
)
ORDER BY NEWID();
-- Result 17 Nov 2026: 5 of 20 correct (25%); 15 errors, mostly location ('old Amsterdam',
-- 'real Amsterdam', 'local feel'...), plus 'Old Amsterdam' cheese (1); correct matches all
-- describe building style ('Dutch style', 'Amsterdam style'); decision for v1.0:
-- merge style words into H1 (option B); see keyword_test_log

-- Step 5f: Read a random sample of H6 matches (positive text)
-- Reason: check that H6 keywords describe spaces or experiences guests enjoy in the hotel;
-- check_words to watch: courtyard (hotel name 'Courtyard by Marriott'),
-- garden (hotel name 'Bilderberg Garden Hotel'), lounge/terrace/rooftop (also modern hotels)
-- Method: 20 random reviews whose positive text contains at least one H6 keyword
-- Expected: most of the 20 describe a hotel space or activity the guest enjoyed; no NULLs
SELECT TOP 20
	r.hotel_name,
	r.positive_review
FROM dbo.amsterdam_reviews_clean AS r
WHERE EXISTS (
	SELECT 1
	FROM dbo.theme_keywords_raw AS k
	WHERE k.theme_id = 'H6'
	  AND r.positive_review LIKE '%' + k.keyword + '%'
)
ORDER BY NEWID();
-- Result 17 Nov 2026: 19 of 20 correct (95%); only error: 'library' next door to the hotel (1);
-- hotel-name traps not seen in sample; keep theme as is; see keyword_test_log

-- Step 5g: Read a random sample of H7 matches (positive text)
-- Reason: check that H7 keywords describe the hotel as unique or distinctive;
-- check_words to watch: boutique (hotel names 'Apollofirst Boutique Hotel',
-- 'Boutique Hotel Notting Hill'), unique (also modern design hotels),
-- memorable (can describe service or an occasion)
-- Method: 20 random reviews whose positive text contains at least one H7 keyword
-- Expected: most of the 20 describe the hotel as unique, distinctive or boutique; no NULLs
SELECT TOP 20
	r.hotel_name,
	r.positive_review
FROM dbo.amsterdam_reviews_clean AS r
WHERE EXISTS (
	SELECT 1
	FROM dbo.theme_keywords_raw AS k
	WHERE k.theme_id = 'H7'
	  AND r.positive_review LIKE '%' + k.keyword + '%'
)
ORDER BY NEWID();
-- Result 17 Nov 2026: 17 of 20 correct (85%); errors: hotel name 'Boutique Hotel Notting Hill' (1),
-- 'memorable' about staff or occasion (2); remove 'memorable'; see keyword_test_log

-- Step 5h: Read a random sample of G3 matches (positive text)
-- Reason: are the matches really about location?
-- check_words to watch: near (also “nearly”), close to (“close to perfect”), central (“central heating”), 
-- museum (the hotel name NH Amsterdam Museum Quarter), vondelpark (Park Plaza Vondelpark)
-- Method: 20 random reviews whose positive text contains at least one G3 keyword
-- Expected: most of the 20 describe the location; no NULLs
SELECT TOP 20
	r.hotel_name,
	r.positive_review
FROM dbo.amsterdam_reviews_clean AS r
WHERE EXISTS (
	SELECT 1
	FROM dbo.theme_keywords_raw AS k
	WHERE k.theme_id = 'G3'
	AND r.positive_review LIKE '%' + k.keyword + '%'
	)
ORDER BY NEWID();
-- Result 17 Nov 2026: 20 of 20 correct (100%); 'near' once used for 'near the window', but that
-- review also mentioned the metro; keep theme; add location phrases removed from H5
-- (old Amsterdam, real Amsterdam, Amsterdam feel, local feel, like a local, very Amsterdam);
-- see keyword_test_log

-- Step 5i: Read a random sample of G7 matches (positive text)
-- Reason: how many “quiet” matches mean “not busy” rather than “no noise”?
-- check_words: creak (also G9), bells (heritage or noise?), construction (also renovation)
-- Method: 20 random reviews whose positive text contains at least one G7 keyword
-- Expected: most of the 20 describe the noise levels; no NULLs
SELECT TOP 20
	r.hotel_name,
	r.positive_review
FROM dbo.amsterdam_reviews_clean AS r
WHERE EXISTS (
	SELECT 1
	FROM dbo.theme_keywords_raw AS k
	WHERE k.theme_id = 'G7'
	AND r.positive_review LIKE '%' + k.keyword +'%'
	)
ORDER BY NEWID();
-- Result 17 Nov 2026: 18 of 20 correct (90%); errors: 'quiet' as a typo for 'quite' (1),
-- 'quiet bar' = not busy (1); quiet location/street counted as noise (overlaps G3);
-- keep 'quiet'; see keyword_test_log

-- Step 5j: Read a random sample of G9 matches (positive text)
-- Reason: G9 is about the condition of the hotel; in positive text, check whether the matches
-- are about condition (praise like 'recently renovated' counts as correct)
-- or about something else
-- check_words: renovat, refurbish (praise: 'recently renovated'), old fashioned (praise of style),
-- broken (also 'broken English'), creak (also noise, G7)
-- Method: 20 random reviews whose positive text contains at least one G9 keyword
-- Expected: most of the 20 describe the condition of the hotel, mostly as praise
-- (renovated, refurbished); no NULLs
SELECT TOP 20
	r.hotel_name,
	r.positive_review
FROM dbo.amsterdam_reviews_clean AS r
WHERE EXISTS (
	SELECT 1
	FROM dbo.theme_keywords_raw AS k
	WHERE k.theme_id = 'G9'
	  AND r.positive_review LIKE '%' + k.keyword + '%'
)
ORDER BY NEWID();
-- Result 17 Nov 2026: 17 of 20 about condition (85%), mostly renovation praise;
-- errors: 'maintenance' = staff (2), 'rust' inside 'frustrated' (1);
-- 'dated room' matched 'updated room' (still condition); one review describes a London hotel
-- (data quality note); see keyword_test_log

-- Step 6: Import theme dictionary version 1.0
-- Source file: data/clean/theme_keywords_v1.0.txt (Unicode text, tab-separated;
-- Power Query from docs/theme_dictionary_v1.0.xlsx: keywords split into rows, trimmed)
-- Method: SSMS Import Flat File into dbo.theme_keywords_v1
-- (theme_id nvarchar(10), keyword nvarchar(100); no nulls allowed)
-- Note: dbo.theme_keywords_raw keeps the tested version 0.4 and is not changed
-- Expected: 291 rows; 14 themes (H2 and H5 merged into H1)

-- Note 17 Nov 2026: the import created the table as [theme_keywords_v1.0] (dot taken from the file name);
--   renamed, because a dot in a name requires brackets in every query:
-- EXEC sp_rename 'dbo.[theme_keywords_v1.0]', 'theme_keywords_v1';

-- Check 6a: Were all keywords of every theme imported, and are H2 and H5 gone?
-- Reason: a per-theme count shows if a theme is missing or incomplete;
-- GROUP BY would show H2 or H5 as their own rows if any were left
-- Expected: 14 rows, no H2 or H5:
--   G1 18, G2 23, G3 38, G4 17, G5 20, G6 16, G7 12, G8 12, G9 24,
--   H1 41, H3 23, H4 17, H6 18, H7 12 (total 291)
SELECT
	theme_id,
	COUNT(*) AS number_of_keywords
FROM dbo.theme_keywords_v1
GROUP BY theme_id
ORDER BY theme_id;
-- Result 17 Nov 2026: 14 themes, 291 keywords; every theme matches; no H2 or H5 - matches expectation

-- Note 17 Nov 2026: column 'keywords' in theme_keywords_v1 renamed to 'keyword'
--   (same name as in theme_keywords_raw):
-- EXEC sp_rename 'dbo.theme_keywords_v1.keywords', 'keyword', 'COLUMN';

-- Step 7a: Re-test the merged H1 (v1.0) with a random sample (positive text)
-- Reason: H1 now combines H1, H2 (original features) and building-style words from H5;
-- check that the merged theme still matches the building and its interior
-- Method: 20 random reviews whose positive text contains at least one H1 keyword
-- from dbo.theme_keywords_v1
-- Expected: at least 16 of 20 (80%) describe the historic building, its style or interior; no NULLs
SELECT TOP 20
	r.hotel_name,
	r.positive_review
FROM dbo.amsterdam_reviews_clean AS r
WHERE EXISTS (
	SELECT 1
	FROM dbo.theme_keywords_v1 AS k
	WHERE k.theme_id = 'H1'
	  AND r.positive_review LIKE '%' + k.keyword + '%'
)
ORDER BY NEWID();
-- Result 17 Nov 2026: 11 of 20 correct (55%); errors: 'diamond factory' = nearby attraction (2),
--   'Dutch house' (music), 'Dutch style' (service), 'typical Dutch' (comparison),
--   'architecture' = modern (2), hotel name 'Canal House' (1), neighbouring building (1);
--   remove 5 keywords; combined with sample 5a: 28 of 34 = 82%; see keyword_test_log

-- Step 7b: Remove 4 noisy H1 keywords found in the re-test (sample 7a)
-- Reason: diamond factory = nearby attraction; Dutch house = music genre;
-- Dutch style = service; typical Dutch = comparison (see keyword_test_log)
-- 'architecture' is kept (known limitation)

-- Preview: which rows will be deleted?
-- Expected: 4 rows
SELECT
	theme_id,
	keyword
FROM dbo.theme_keywords_v1
WHERE theme_id = 'H1'
  AND keyword IN ('diamond factory', 'Dutch house', 'Dutch style', 'typical Dutch');
-- Result 17 Nov 2026: 4 rows: diamond factory, typical Dutch, Dutch style, Dutch house - matches expectation

-- Delete (run only after the preview shows exactly these 4 rows)
-- Expected: 4 rows affected
DELETE FROM dbo.theme_keywords_v1
WHERE theme_id = 'H1'
  AND keyword IN ('diamond factory', 'Dutch house', 'Dutch style', 'typical Dutch');
-- Result 17 Nov 2026: 4 rows affected - matches expectation

-- Check 7c: Final check of dictionary version 1.0 after the H1 re-test
-- Reason: confirm the table holds exactly the frozen version before the analysis starts
--   (14 themes; H2 and H5 merged into H1; 4 noisy H1 keywords removed in Step 7b)
-- Expected: 14 rows, no H2 or H5; sorted by theme_id to compare with the list below:
--   G1 18, G2 23, G3 38, G4 17, G5 20, G6 16, G7 12, G8 12, G9 24,
--   H1 37, H3 23, H4 17, H6 18, H7 12 (total 287)
SELECT
	theme_id,
	COUNT(*) AS number_of_keywords
FROM dbo.theme_keywords_v1
GROUP BY theme_id
ORDER BY theme_id;
-- Result 17 Nov 2026: 14 themes, 287 keywords; H1 37 (was 41); all other themes unchanged;
--   no H2 or H5 - matches expectation
-- Dictionary version 1.0 frozen: Stage 5 uses dbo.theme_keywords_v1 only
--   (see decision log, 17 Nov 2026)

-- Note 17 Nov 2026: theme_keywords_v1.0.txt was re-exported after Step 7b (287 keywords),
--   so the file matches dbo.theme_keywords_v1; no re-import needed
--   (the table was corrected directly with the DELETE in Step 7b)

