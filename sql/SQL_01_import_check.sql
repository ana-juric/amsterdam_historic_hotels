/* ============================================================
   Project:  Guest experience in historic hotels
   File:     01_import_check.sql
   Purpose:  Check that the raw CSV was imported completely
   Author:   Ana Juric
   Date:     5 Nov 2026
   Source:   Hotel_Reviews.csv (Kaggle, 515K Hotel Reviews Data in Europe)
   ============================================================ */

-- make sure the query runs in the right database
USE hotel_reviews;   

-- Check 1: Row count should equal the CSV (515,738 rows)
-- Result 5 Nov 2026: 515,738 - OK
SELECT COUNT(*) AS row_count
FROM dbo.hotel_reviews_raw

