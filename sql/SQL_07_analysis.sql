-- =========================================================
-- 07_analysis.sql
-- Project 1: Guest experience in historic hotels (Amsterdam)
-- Stage 5: Analysis
-- Author: Ana Juric
-- Started: 18 Nov 2026 (restored 23 Nov 2026)
-- Research question: What do guests praise and criticise in historic hotels
-- compared with other hotels in Amsterdam, and which nationalities value heritage most?
-- =========================================================

USE hotel_reviews;

-- STEP 1: BUILD THE THEME MATCH TABLE

-- Step 1a: Theme matches in the positive text (preview)
-- Reason: Find which themes each review mentions in its positive text.
-- One row = one theme in one review, positive side. DISTINCT removes double counting
-- when several keywords of the same theme match (e.g. "building" and "old building").
-- Expected: Each review appears at most 14 times (one per theme).
-- Reviews with no theme or NULL positive text do not appear. No errors.
SELECT DISTINCT
    r.review_id,
    k.theme_id,
    'positive' AS text_side
FROM dbo.amsterdam_reviews_clean AS r
JOIN dbo.theme_keywords_v1 AS k
    ON r.positive_review LIKE '%' + k.keyword + '%';
-- Result 18 Nov 2026: 110,075 rows. Checks on duplicates, reviews and themes: see Step 2.


-- Step 1b: Theme matches in the negative text (preview)
-- Reason:   Find which themes each review mentions in its negative text.
-- One row = one theme in one review, negative side. DISTINCT removes double counting
-- when several keywords of the same theme match (e.g. "noise" and "noisy").
-- Expected: Each review appears at most 14 times (one per theme).
-- Reviews with no theme or NULL negative text do not appear. No errors.
SELECT DISTINCT
    r.review_id,
    k.theme_id,
    'negative' AS text_side
FROM dbo.amsterdam_reviews_clean AS r
JOIN dbo.theme_keywords_v1 AS k
    ON r.negative_review LIKE '%' + k.keyword + '%';
-- Result 18 Nov 2026: 63,404 rows. Checks: see Step 2.


-- Step 1c: Save all theme matches as a table
-- Reason:   Run the slow LIKE search once and store the result, so every later
-- query counts from the same table (faster and consistent).
-- One row = one theme in one review, on one text side (positive or negative).
-- UNION ALL stacks the positive half (1a) and the negative half (1b).
-- Expected: 110,075 + 63,404 = 173,479 rows. No errors.
-- Already run 18 Nov 2026 (rebuilt 19 Nov 2026). Do not run again.
-- SELECT DISTINCT
--     r.review_id,
--     k.theme_id,
--     'positive' AS text_side
-- INTO dbo.review_theme_matches
-- FROM dbo.amsterdam_reviews_clean AS r
-- JOIN dbo.theme_keywords_v1 AS k
--     ON r.positive_review LIKE '%' + k.keyword + '%'
-- UNION ALL
-- SELECT DISTINCT
--     r.review_id,
--     k.theme_id,
--     'negative' AS text_side
-- FROM dbo.amsterdam_reviews_clean AS r
-- JOIN dbo.theme_keywords_v1 AS k
--     ON r.negative_review LIKE '%' + k.keyword + '%';
-- Result 18 Nov 2026: 173,479 rows affected. Matches expected (110,075 + 63,404).
-- Rebuilt 19 Nov 2026 on second computer: Step 0 OK (14 themes, 287 keywords),
-- 173,479 rows affected (identical to 18 Nov).


-- STEP 2: CHECK THE MATCH TABLE

-- Step 2a: Duplicate check on the match table
-- Reason:   The grain is one theme in one review on one text side.
-- Each combination of review_id + theme_id + text_side must appear only once,
-- otherwise reviews would be counted twice in the analysis.
-- Expected: 0 rows.
SELECT
    review_id,
    theme_id,
    text_side,
    COUNT(*) AS number_of_rows
FROM dbo.review_theme_matches
GROUP BY review_id, theme_id, text_side
HAVING COUNT(*) > 1;
-- Result 18 Nov 2026: 0 rows. Matches expected: no duplicates, grain is clean.


-- Step 2b: Number of different reviews per text side
-- Reason:   One review can have up to 14 rows (one per theme), so COUNT(*) counts
-- rows, not reviews. COUNT(DISTINCT review_id) counts each review only once.
-- Verifies the 48,938 found in Step 1a.
-- Expected: positive 48,938; negative lower than positive; both below 57,202.
SELECT
    text_side,
    COUNT(DISTINCT review_id) AS number_of_reviews
FROM dbo.review_theme_matches
GROUP BY text_side;
-- Result 18 Nov 2026: positive 48,938 reviews; negative 33,916 reviews.
-- Matches expected: positive = Step 1a count; negative lower; both below 57,202.
-- Coverage: 85.6% of all reviews (positive), 59.3% (negative).
-- Of reviews WITH text: 92% positive (48,938 of 53,375), 79% negative (33,916 of 42,841).


-- Step 2c: Most themes in one review (per text side)
-- Reason:   Each review can mention each of the 14 themes at most once per side.
-- A number above 14 would mean duplicate rows in the match table.
-- Expected: highest number_of_themes is 14 or lower.
SELECT TOP 5
    review_id,
    text_side,
    COUNT(*) AS number_of_themes
FROM dbo.review_theme_matches
GROUP BY review_id, text_side
ORDER BY number_of_themes DESC;
-- Result 18 Nov 2026: highest = 9 themes (review 56350 negative; 34380, 56664,
-- 14356, 49266 positive). Matches expected: 14 or lower.


-- Step 2d: Reviews per theme, positive vs negative
-- Reason:   First overview of the match table and verification of the theme counts
-- from Step 1a. CASE WHEN inside COUNT (conditional aggregation) puts positive and
-- negative side by side: one row per theme.
-- Expected: 14 rows; positive H1 343, H3 209, H4 72, H6 1,229, H7 451.
SELECT
    theme_id,
    COUNT(DISTINCT CASE WHEN text_side = 'positive' THEN review_id END) AS positive_reviews,
    COUNT(DISTINCT CASE WHEN text_side = 'negative' THEN review_id END) AS negative_reviews
FROM dbo.review_theme_matches
GROUP BY theme_id
ORDER BY theme_id;
-- Result 18 Nov 2026: 14 rows; every theme appears on both sides. Heritage counts match Step 1a.
-- G1 25,283 / 8,039; G2 26,577 / 20,743; G3 25,287 / 5,447; G4 8,793 / 4,022;
-- G5 14,230 / 9,125; G6 3,302 / 8,601; G7 2,966 / 3,243; G8 1,017 / 1,979; G9 316 / 1,486;
-- H1 343 / 113; H3 209 / 66; H4 72 / 16; H6 1,229 / 465; H7 451 / 59.
-- More criticism than praise: G6 price, G8 stairs/lift, G9 condition, G7 noise.
-- Heritage is mostly praise (e.g. H1 343 positive vs 113 negative) but rare overall.

-- Step 3: Review scores, historic vs other hotels
-- Reason:   Big picture before the themes: are historic hotels rated higher, lower
-- or the same as other hotels? This is the context for every theme result.
-- The score is in the reviews table, the label in the hotels table, so we JOIN them.
-- Expected: 2 rows; historic 23,962 reviews, other 33,240 (Stage 3, Check 7c);
-- average scores between 1 and 10, probably around 8.
SELECT
    h.label,
    COUNT(*) AS number_of_reviews,
    ROUND(AVG(CAST(r.reviewer_score AS DECIMAL(4,2))), 2) AS average_score
FROM dbo.amsterdam_reviews_clean AS r
JOIN dbo.amsterdam_hotels AS h
    ON r.hotel_name = h.hotel_name
GROUP BY h.label
ORDER BY h.label;
-- Result 18 Nov 2026: historic 23,962 reviews, avg 8.53; other 33,240 reviews, avg 8.40.
-- Review counts match Stage 3 Check 7c. Historic +0.13 points: small; check
-- reliability in Step 8 and possible location effect (G3 control).

-- STEP 4: PRAISE PER THEME

-- Step 4a: Praise per theme, historic vs other (counts)
-- Reason:   Core of the research question: what do guests praise in historic hotels
-- compared with other hotels? Positive text only. Three tables: matches (theme) ->
-- reviews (hotel_name) -> hotels (label).
-- Expected: 14 rows; historic_praise + other_praise = positive_reviews from Step 2d
-- (e.g. H1: 343).
SELECT
    m.theme_id,
    COUNT(DISTINCT CASE WHEN h.label = 'historic' THEN m.review_id END) AS historic_praise,
    COUNT(DISTINCT CASE WHEN h.label = 'other'    THEN m.review_id END) AS other_praise
FROM dbo.review_theme_matches AS m
JOIN dbo.amsterdam_reviews_clean AS r
    ON m.review_id = r.review_id
JOIN dbo.amsterdam_hotels AS h
    ON r.hotel_name = h.hotel_name
WHERE m.text_side = 'positive'
GROUP BY m.theme_id
ORDER BY m.theme_id;
-- Result 18 Nov 2026: 14 rows. historic_praise + other_praise = Step 2d positive_reviews
-- for every theme (checked). Counts not comparable yet: groups differ in size -> Step 4b.


-- Step 4b: Praise per theme as a percentage of each group
-- Reason:   Groups differ in size (historic 23,962 vs other 33,240 reviews), so counts
-- cannot be compared. Percentage = reviews praising the theme / all reviews in the group.
-- Group totals are hardcoded from Step 3 (verified). 100.0 avoids integer division.
-- Expected: 14 rows; G3 historic about 51.56, other 38.90.
SELECT
    m.theme_id,
    ROUND(COUNT(DISTINCT CASE WHEN h.label = 'historic' THEN m.review_id END)
          * 100.0 / 23962, 2) AS historic_praise_pct,
    ROUND(COUNT(DISTINCT CASE WHEN h.label = 'other'    THEN m.review_id END)
          * 100.0 / 33240, 2) AS other_praise_pct
FROM dbo.review_theme_matches AS m
JOIN dbo.amsterdam_reviews_clean AS r
    ON m.review_id = r.review_id
JOIN dbo.amsterdam_hotels AS h
    ON r.hotel_name = h.hotel_name
WHERE m.text_side = 'positive'
GROUP BY m.theme_id
ORDER BY m.theme_id;
-- Result 18 Nov 2026: Heritage praised far more in historic hotels: H3 0.76 vs 0.08,
-- H1 1.23 vs 0.14, H4 0.25 vs 0.04, H7 1.17 vs 0.51; H6 equal (2.09 vs 2.19).
-- Heritage praise rare (about 1% of reviews). Historic higher on G3 location (+12.7)
-- and G1 staff (+4.4); lower on G4 cleanliness (-7.3) and G2 room (-7.1).
-- Small groups (H4) and location confounding: check in Step 8.


-- STEP 5: CRITICISM PER THEME

-- Step 5: Criticism per theme as a percentage of each group
-- Reason:   Same as Step 4b, but for the negative text: what do guests criticise in
-- historic hotels compared with other hotels? Same denominators (all reviews in the group).
-- Expected: 14 rows; heritage percentages very small (H1 has 113 negative reviews in total).
SELECT
    m.theme_id,
    ROUND(COUNT(DISTINCT CASE WHEN h.label = 'historic' THEN m.review_id END)
          * 100.0 / 23962, 2) AS historic_criticism_pct,
    ROUND(COUNT(DISTINCT CASE WHEN h.label = 'other'    THEN m.review_id END)
          * 100.0 / 33240, 2) AS other_criticism_pct
FROM dbo.review_theme_matches AS m
JOIN dbo.amsterdam_reviews_clean AS r
    ON m.review_id = r.review_id
JOIN dbo.amsterdam_hotels AS h
    ON r.hotel_name = h.hotel_name
WHERE m.text_side = 'negative'
GROUP BY m.theme_id
ORDER BY m.theme_id;
-- Result 18 Nov 2026: historic criticised more for G7 noise (8.03 vs 3.97), G9 condition
-- (3.66 vs 1.83), G8 stairs (4.41 vs 2.77), G2 room (39.18 vs 34.16); less for G3 location
-- (5.08 vs 12.72) and G5 food (14.49 vs 17.01). G1, G4, G6 about equal.
-- Heritage criticism tiny in both groups (all below 1%).


-- STEP 6: HERITAGE OVERALL

-- Step 6: Heritage overall: reviews mentioning any heritage theme
-- Reason:   Each heritage theme is small (about 1%). Together they show how many guests
-- mention heritage at all: the headline number of the project. A review mentioning
-- several H themes is counted once (COUNT DISTINCT). Same denominators as Steps 4b and 5.
-- Expected: 2 rows (negative, positive). Ranges from Steps 4b and 5:
-- positive historic 2.09-5.50, other 2.19-2.96; negative historic 0.88-1.58, other 0.76-1.02.
SELECT
    m.text_side,
    ROUND(COUNT(DISTINCT CASE WHEN h.label = 'historic' THEN m.review_id END)
          * 100.0 / 23962, 2) AS historic_heritage_pct,
    ROUND(COUNT(DISTINCT CASE WHEN h.label = 'other'    THEN m.review_id END)
          * 100.0 / 33240, 2) AS other_heritage_pct
FROM dbo.review_theme_matches AS m
JOIN dbo.amsterdam_reviews_clean AS r
    ON m.review_id = r.review_id
JOIN dbo.amsterdam_hotels AS h
    ON r.hotel_name = h.hotel_name
WHERE m.theme_id LIKE 'H%'
GROUP BY m.text_side
ORDER BY m.text_side;
-- Result 18 Nov 2026: positive historic 4.97 vs other 2.90 (1.7x, +2.07 points);
-- negative historic 1.52 vs other 1.02. All within expected ranges.
-- Praise-to-criticism ratio similar: 3.3 (historic) vs 2.8 (other).
-- Other hotels' heritage share is mostly H6 (2.19), which is not heritage-specific.

-- STEP 7: NATIONALITIES

-- Step 7a: Number of reviews per nationality in historic hotels
-- Reason:   Before ranking nationalities by heritage praise, we need group sizes.
-- Small groups give extreme percentages by chance, so they need a minimum (Step 7b).
-- Expected: counts add up to 23,962 (all historic reviews, Step 3).
SELECT
    r.nationality_group,
    COUNT(*) AS historic_reviews
FROM dbo.amsterdam_reviews_clean AS r
JOIN dbo.amsterdam_hotels AS h
    ON r.hotel_name = h.hotel_name
WHERE h.label = 'historic'
GROUP BY r.nationality_group
ORDER BY historic_reviews DESC;
-- Result 18 Nov 2026: 20 groups; sum = 23,962 (matches Step 3).
-- Largest: United Kingdom 9,296; Other 4,299; USA 2,817; Ireland 1,137; Australia 1,031.
-- Smallest named: Italy 208; India 206; Unknown 19.
-- "Other" is a mixed group of many countries, not a nationality.


-- Decision (Step 7b), 18 Nov 2026:
-- Exclude "Other" (mixed group, not a nationality) and "Unknown" (19 reviews).
-- Minimum group size: 500 reviews in historic hotels, set before seeing heritage results.
-- Reason: at about 5% heritage praise, margin of error is about +/-1.9 points at 500 reviews
-- (+/-2.5 at 300). 500 keeps 8 nationalities, including the Netherlands.
-- Included: United Kingdom, USA, Ireland, Australia, Israel, UAE, Netherlands, Canada.


-- Step 7c: Heritage praise per nationality in historic hotels
-- Reason: Research question: which nationalities value heritage most?
-- % of each nationality's historic reviews that praise any heritage theme (H1-H7).
-- Each nationality has its own denominator, so SQL counts it (COUNT(*)).
-- Heritage reviews come from a subquery with one row per review, so the
-- reviews table keeps one row = one review.
-- Only the 8 nationalities with 500+ historic reviews (decision Step 7b).
-- Expected: 8 rows; historic_reviews match Step 7a; percentages around 4.97 (Step 6).
SELECT
    r.nationality_group,
    COUNT(*) AS historic_reviews,
    COUNT(hp.review_id) AS heritage_praise_reviews,
    ROUND(COUNT(hp.review_id) * 100.0 / COUNT(*), 2) AS heritage_praise_pct
FROM dbo.amsterdam_reviews_clean AS r
JOIN dbo.amsterdam_hotels AS h
    ON r.hotel_name = h.hotel_name
LEFT JOIN (
    SELECT DISTINCT review_id
    FROM dbo.review_theme_matches
    WHERE theme_id LIKE 'H%'
      AND text_side = 'positive'
) AS hp
    ON r.review_id = hp.review_id
WHERE h.label = 'historic'
  AND r.nationality_group IN (
      'United Kingdom',
      'United States of America',
      'Ireland',
      'Australia',
      'Israel',
      'United Arab Emirates',
      'Netherlands',
      'Canada')
GROUP BY r.nationality_group
ORDER BY heritage_praise_pct DESC;
-- Result 18 Nov 2026: 8 rows; group sizes match Step 7a.
-- Canada 9.23, USA 8.20, Australia 7.47, Netherlands 6.36, UK 4.22, UAE 3.59,
-- Ireland 3.34, Israel 2.81 (% of historic reviews praising heritage).
-- Reliable: USA/Canada/Australia about 2x UK/Ireland (ranges do not overlap for USA vs UK).
-- Not reliable: exact ranking among the top 3 (margins of error overlap).
-- Cautions: English keywords (non-native writers), hotel choice may differ by nationality.


-- STEP 8: RELIABILITY AND ROBUSTNESS

-- Step 8a: Robustness check: core heritage (H1, H3, H4, H7, without H6)
-- Reason: H6 (bars, gardens, lounges) is praised equally in both groups (Step 4b),
-- so it is not specific to heritage and inflated other hotels' share in Step 6.
-- Core heritage = building, history, atmosphere, uniqueness.
-- A review mentioning several core themes is counted once (COUNT DISTINCT).
-- Expected: 2 rows. Positive historic 1.23-3.41, other 0.51-0.77;
-- negative historic 0.37-0.70, other 0.08-0.26 (ranges from Steps 4b and 5).
SELECT
    m.text_side,
    ROUND(COUNT(DISTINCT CASE WHEN h.label = 'historic' THEN m.review_id END)
          * 100.0 / 23962, 2) AS historic_core_heritage_pct,
    ROUND(COUNT(DISTINCT CASE WHEN h.label = 'other'    THEN m.review_id END)
          * 100.0 / 33240, 2) AS other_core_heritage_pct
FROM dbo.review_theme_matches AS m
JOIN dbo.amsterdam_reviews_clean AS r
    ON m.review_id = r.review_id
JOIN dbo.amsterdam_hotels AS h
    ON r.hotel_name = h.hotel_name
WHERE m.theme_id IN ('H1', 'H3', 'H4', 'H7')
GROUP BY m.text_side
ORDER BY m.text_side;
-- Result 19 Nov 2026: positive historic 3.09 vs other 0.75 (about 4x; Step 6 with H6: 1.7x);
-- negative historic 0.65 vs other 0.26. All within expected ranges.
-- Praise per criticism: historic 4.8, other 2.9.
-- Conclusion: report core heritage (3.09 vs 0.75) as the main heritage result;
-- the Step 6 figures (with H6) only as background.


-- Step 8b: Core heritage praise per historic hotel
-- Reason: Check whether heritage praise is spread across many historic hotels or
-- driven by a few. If a few hotels dominate, the finding is about them, not about
-- historic hotels in general. Same pattern as Step 7c: each hotel has its own denominator.
-- Expected: 10 rows; percentages above and below the overall 3.09% (Step 8a).
SELECT TOP 10
    h.hotel_name,
    COUNT(*) AS hotel_reviews,
    COUNT(hp.review_id) AS core_heritage_praise_reviews,
    ROUND(COUNT(hp.review_id) * 100.0 / COUNT(*), 2) AS core_heritage_praise_pct
FROM dbo.amsterdam_reviews_clean AS r
JOIN dbo.amsterdam_hotels AS h
    ON r.hotel_name = h.hotel_name
LEFT JOIN (
    SELECT DISTINCT review_id
    FROM dbo.review_theme_matches
    WHERE theme_id IN ('H1', 'H3', 'H4', 'H7')
      AND text_side = 'positive'
) AS hp
    ON r.review_id = hp.review_id
WHERE h.label = 'historic'
GROUP BY h.hotel_name
ORDER BY core_heritage_praise_pct DESC;
-- Result 19 Nov 2026 (top 10): highest Seven One Seven 29.41% (5 of 17 reviews) and
-- InterContinental 11.76% (4 of 34): too few reviews to interpret.
-- Reliable high values: Amrath 14.34% (530), Canal House 12.50% (184, check hotel-name trap),
-- Pulitzer 10.00% (300), Arena 8.64% (405), Ambassade 8.35% (551), De Hallen 8.17% (355).
-- Top 10 = about 273 of about 740 core heritage reviews (about a third).


-- Step 8c: Core heritage praise for all 49 historic hotels
-- Reason: Same query as 8b without TOP 10, to see the full spread.
-- Expected: 49 rows; sum of core heritage reviews = about 740 (3.09% of 23,962).
SELECT
    h.hotel_name,
    COUNT(*) AS hotel_reviews,
    COUNT(hp.review_id) AS core_heritage_praise_reviews,
    ROUND(COUNT(hp.review_id) * 100.0 / COUNT(*), 2) AS core_heritage_praise_pct
FROM dbo.amsterdam_reviews_clean AS r
JOIN dbo.amsterdam_hotels AS h
    ON r.hotel_name = h.hotel_name
LEFT JOIN (
    SELECT DISTINCT review_id
    FROM dbo.review_theme_matches
    WHERE theme_id IN ('H1', 'H3', 'H4', 'H7')
      AND text_side = 'positive'
) AS hp
    ON r.review_id = hp.review_id
WHERE h.label = 'historic'
GROUP BY h.hotel_name
ORDER BY core_heritage_praise_pct DESC;
-- Result 19 Nov 2026: 49 hotels; sum 740 core heritage reviews of 23,962 (= 3.09%, matches 8a).
-- 36 of 49 above other hotels' average (0.75%); with 100+ reviews: 33 of 46.
-- Only Royal Amsterdam = 0. Top 10 = 37% of core heritage praise: spread, not concentrated.
-- Lowest: large chain hotels in listed buildings (NH Carlton 0.27, Krasnapolsky 0.48,
-- Radisson 0.42, Swissotel 0.36, Hilton 0.36): heritage possibly not visible to guests.


-- Step 8d: Hotel-name trap check: keywords containing "canal"
-- Reason: Canal House scored 12.50% core heritage (Step 8b). If "canal house" is a
-- keyword, guests naming the hotel would be counted as heritage praise.
-- Expected: 0 or 1 row.
SELECT
    theme_id,
    keyword
FROM dbo.theme_keywords_v1
WHERE keyword LIKE '%canal%';
-- Result 19 Nov 2026: 1 row: H1 "canal house". Trap possible: check Canal House reviews (8e).


-- Step 8e: Canal House: does "canal house" match the hotel name?
-- Reason: Keyword "canal house" (H1) can match the hotel's own name, which would
-- inflate Canal House's core heritage score (12.50%, Step 8b).
-- Expected: some rows; read each and judge: hotel name or building description?
SELECT
    positive_review
FROM dbo.amsterdam_reviews_clean
WHERE hotel_name = 'Canal House'
  AND positive_review LIKE '%canal house%';
-- Result 19 Nov 2026: 9 rows; all 9 use "Canal House" as the hotel name (manual reading).
-- Canal House core heritage is between 7.61% (14 of 184, if all 9 are removed)
-- and 12.50% (23 of 184, as measured); still well above average.
-- Effect on overall result: at most 9 of 740 reviews (3.09% -> at least 3.05%): negligible.
-- Dictionary not changed (frozen v1.0); logged as known limitation.


-- Step 8f: Test the city-centre pattern (postcodes 1011-1018)
-- Reason: Before comparing hotels in the same area, check that the postcode pattern
-- catches the right hotels. The postcode comes just before "Amsterdam"; house numbers
-- cannot match because the pattern requires 2 letters + "Amsterdam" after the digits.
-- Expected: a list of hotels in the old centre, canal belt, Jordaan and Plantage.
SELECT DISTINCT
    hotel_name,
    hotel_address
FROM dbo.amsterdam_reviews_clean
WHERE hotel_address LIKE '% 101[1-8] [A-Z][A-Z] Amsterdam%';
-- Result 19 Nov 2026: 46 hotels. 44 have "Amsterdam City Center" in the address;
-- 2 do not: Golden Tulip Amsterdam West (1014 AG, no district) and
-- WestCord Art Hotel (1013 ZX, Westerpark). Postcode range catches non-central hotels.
-- Decision: define centre by Booking's district label "Amsterdam City Center" instead.


-- Step 8f (second test): hotels outside the city centre
-- Reason: A filter can fail in two ways: catch wrong hotels (first test) or miss
-- right ones. List every hotel whose address does not contain "Amsterdam City Center"
-- and read the addresses: does any still look central?
-- amsterdam_hotels has one row per hotel and holds both address and label.
-- Expected: 60 hotels (105 minus 45 with "Amsterdam City Center").
SELECT
    hotel_name,
    hotel_address,
    label
FROM dbo.amsterdam_hotels
WHERE hotel_address NOT LIKE '%Amsterdam City Center%'
ORDER BY label, hotel_name;
-- Result 19 Nov 2026: 60 hotels outside the centre: 15 historic, 45 other.
-- So centre: 34 historic, 11 other. No canal (gracht) address outside: definition OK.
-- Location and heritage strongly linked: 69% of historic vs 20% of other hotels central.
-- Note: Andaz has a wrong postcode (1067 HT) but is correctly central via the district label.


-- Step 8g: Review scores in the city centre only, historic vs other
-- Reason: 69% of historic but only 20% of other hotels are central (Step 8f), so the
-- overall score difference (8.53 vs 8.40, Step 3) may be a location effect.
-- Comparing only central hotels removes most of that effect.
-- Centre = address contains "Amsterdam City Center" (decision Step 8f).
-- Expected: 2 rows (34 historic, 11 other hotels). If historic still scores higher,
-- location does not explain the whole difference.
SELECT
    h.label,
    COUNT(*) AS number_of_reviews,
    ROUND(AVG(CAST(r.reviewer_score AS DECIMAL(4,2))), 2) AS average_score
FROM dbo.amsterdam_reviews_clean AS r
JOIN dbo.amsterdam_hotels AS h
    ON r.hotel_name = h.hotel_name
WHERE h.hotel_address LIKE '%Amsterdam City Center%'
GROUP BY h.label
ORDER BY h.label;
-- Result 19 Nov 2026: centre only: historic 18,389 reviews, avg 8.58;
-- other 6,243 reviews, avg 8.48. Gap 0.10 (all hotels: 0.13, Step 3).
-- Location explains only a small part: historic hotels still score higher in the centre.
-- Caution: only 11 other hotels in the centre, so a few hotels can move their average.


-- Step 8h: Core heritage praise per nationality (H1, H3, H4, H7)
-- >>> To be written 23 Nov 2026 (copy Step 7c, change the heritage theme line).
-- Step 8h: Core heritage praise per nationality (H1, H3, H4, H7)
-- Reason: Step 7c used all H themes, including H6 (not heritage-specific, Step 8a).
-- For consistency with the headline (core heritage), re-run 7c with the 4 core themes.
-- Only the 8 nationalities with 500+ historic reviews (decision Step 7b).
-- Expected: 8 rows; historic_reviews same as 7c (UK 9,296 ...); percentages around 3.09 (Step 8a).
SELECT
    r.nationality_group,
    COUNT(*) AS historic_reviews,
    COUNT(hp.review_id) AS core_heritage_praise_reviews,
    ROUND(COUNT(hp.review_id) * 100.0 / COUNT(*), 2) AS core_heritage_praise_pct
FROM dbo.amsterdam_reviews_clean AS r
JOIN dbo.amsterdam_hotels AS h
    ON r.hotel_name = h.hotel_name
LEFT JOIN (
    SELECT DISTINCT review_id
    FROM dbo.review_theme_matches
    WHERE theme_id IN ('H1', 'H3', 'H4', 'H7')
      AND text_side = 'positive'
) AS hp
    ON r.review_id = hp.review_id
WHERE h.label = 'historic'
  AND r.nationality_group IN (
      'United Kingdom',
      'United States of America',
      'Ireland',
      'Australia',
      'Israel',
      'United Arab Emirates',
      'Netherlands',
      'Canada')
GROUP BY r.nationality_group
ORDER BY core_heritage_praise_pct DESC;
-- Result 23 Nov 2026: Canada 6.09 (509), USA 5.40 (2,817), Australia 4.85 (1,031),
-- Netherlands 4.73 (550), UK 2.57 (9,296), Ireland 2.37 (1,137), UAE 2.33 (557), Israel 1.72 (640).
-- Same pattern as 7c (with H6): USA about 2.1x UK (7c: 1.9x). Robust to removing H6.
-- Margins of error (95%): USA 4.6-6.2 vs UK 2.3-2.9, no overlap.
-- Netherlands now close to Australia, probably above UK (margin 3.0-6.5).
-- Use these core heritage figures for the dashboard (Page 3).

-- STEP 9: PREPARE TABLES FOR POWER BI

-- Step 9c-1: Add location_area to amsterdam_hotels
-- Reason: Power BI needs centre/outside as a column (for charts and slicers),
-- not only as a WHERE filter. Definition from Step 8f: centre = address contains
-- "Amsterdam City Center". nvarchar(20) like label.
-- Expected: "Commands completed successfully."
-- Already run 19 Nov 2026. Do not run again.
-- ALTER TABLE dbo.amsterdam_hotels
-- ADD location_area nvarchar(20);
-- Result 19 Nov 2026: Commands completed successfully.


-- Step 9c-2: Fill location_area (centre/outside)
-- Reason: Same definition as Step 8f: centre = address contains "Amsterdam City Center"
-- (Booking district); all other hotels = outside. One UPDATE fills all 105 hotels.
-- No WHERE on purpose: every hotel must get a value.
-- Expected: 105 rows affected (45 centre, 60 outside).
-- Already run 19 Nov 2026. Do not run again.
-- UPDATE dbo.amsterdam_hotels
-- SET location_area = CASE
--                         WHEN hotel_address LIKE '%Amsterdam City Center%' THEN 'centre'
--                         ELSE 'outside'
--                     END;
-- Result 19 Nov 2026: 105 rows affected.


-- Check 9c-3: Hotels per label and location_area
-- Reason:   Verify the UPDATE: each combination must match Step 8f,
-- and no hotel may be NULL.
-- Expected: 4 rows: historic centre 34, historic outside 15,
-- other centre 11, other outside 45. No NULL row.
SELECT
    label,
    location_area,
    COUNT(*) AS number_of_hotels
FROM dbo.amsterdam_hotels
GROUP BY label, location_area
ORDER BY label, location_area;
-- Result 19 Nov 2026: historic centre 34, historic outside 15, other centre 11,
-- other outside 45. Matches Step 8f. No NULL row.


-- Step 9c (import): dbo.themes imported 19 Nov 2026 via Import Flat File
-- from data/clean/themes_v1.0.txt (theme_id, theme, theme_group, report_category, definition).


-- Check 9c-4: theme_ids in the match table that are missing from dbo.themes
-- Reason: Power BI links review_theme_matches to themes on theme_id. Every theme_id
-- must exist exactly (no extra spaces, same spelling), otherwise matches lose their
-- theme name in the dashboard.
-- Expected: 0 rows.
SELECT DISTINCT
    theme_id
FROM dbo.review_theme_matches
WHERE theme_id NOT IN (
    SELECT theme_id
    FROM dbo.themes
);
-- Result 19 Nov 2026: 0 rows. All theme_ids in review_theme_matches exist in dbo.themes.

-- Check 9d: Review period
-- Reason: The README states the review period; the number must come from the data.
-- Expected: about August 2015 to August 2017 (Kaggle dataset description).
SELECT
    MIN(review_date) AS earliest_review,
    MAX(review_date) AS latest_review
FROM dbo.amsterdam_reviews_clean;
-- Result 23 Nov 2026: 2015-08-04 to 2017-08-03 (two years).