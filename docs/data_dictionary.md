

|**Column Name**|**Level**|**What it means**|**Example value**|**Data type**|**Questions / issues**|
|-|-|-|-|-|-|
|Hotel\_Address|Hotel|Street, number, postcode, city, country in one field|s Gravesandestraat 55 Oost 1092 AA Amsterdam Netherlands|Text|City and country are combined in one field; we must extract them. Apostrophe missing ('s-Gravesandestraat). Special characters (ä, ß, é, ‘) replaced by spaces. Example: ‘Josefst dter Stra e’ = Josefstädter Straße.|
|Additional\_Number\_of\_Scoring|Hotel|Number of guests who gave a score without writing a review|194|Whole number|-|
|Review\_Date|Review|Date the review was written|8/3/2017|Date|CHECK: month/day or day/month? Format is month/day/year, as visible from 5/21/2017.|
|Average\_Score|Hotel|Hotel's average score|7.7|Decimal number|Excel removed the decimal point. CHECK: missing values?|
|Hotel\_Name|Hotel|Name of the hotel|Hotel Arena|Text|Same hotel with different spellings? Special characters replaced by spaces. Example: ‘Josefst dter Stra e’ = Josefstädter Straße.<br />London: 400 names vs 399 addresses → one address has 2 names (see 02\_data\_profiling.sql, Check 4). Amsterdam: 105 = 105.|
|Reviewer\_Nationality|Review|Nationality of the reviewer|Russia|Text|Nationality ≠ country of residence. CHECK: extra spaces? Empty values?<br />Values have trailing spaces. Check whether the same country appears with and without spaces (check 7).<br />Amsterdam: 179 nationalities + 69 rows with NULL. Values have trailing spaces (e.g. “Egypt “), but trimming doesn’t change the count (Check 7a-2), so no nationality is split into two groups. Trim in clean table for Power BI. Some names lack special characters (“Cura ao”). Very uneven: UK = 40% of reviews; 69% of nationalities have fewer than 100 reviews (Check 7c).|
|Negative\_Review|Review|What the guest disliked|The aircondition makes so much noise and its hard to sleep at night|Text|Placeholder "No Negative" when empty. Guests may also write "Nothing" or "None".<br />NULL = guest wrote nothing (was 'No Negative' / 'No Positive' in the source, or empty in the source).<br />91 rows (Amsterdam) were already NULL in the source, besides the 'No Negative' placeholders (Check 8a).|
|Review\_Total\_Negative\_Word\_Counts|Review|Number of words in a Negative\_Review|397|Whole number|CHECK: Does it match the text in the same row? Tested on 3 rows: count is usually 1–2 higher. Probably counts leading/trailing spaces. Not reliable.|
|Total\_Number\_of\_Reviews|Review|Total number of reviews hotel has|1403|Whole number|May be more than the rows in this dataset.|
|Positive\_Review|Review|What the guest liked|Friendly and helpful staff|Text|Placeholder "No Positive" when empty.<br />Missing text appears in two forms: "No Positive" and NULL. Check how many NULLs.<br />Near-duplicates exist: same guest details, slightly different wording. Not caught by exact-match duplicate check.<br />NULL = guest wrote nothing (was 'No Negative' / 'No Positive' in the source, or empty in the source).<br />15 rows (Amsterdam) were already NULL in the source, besides the 'No Positive' placeholders (Check 8a).|
|Review\_Total\_Positive\_Word\_Counts|Review|Number of words in Positive\_Review|23|Whole number|CHECK: Does it match the text in the same row? Tested on 3 rows: count is usually 1–2 higher. Probably counts leading/trailing spaces. Not reliable.|
|Total\_Number\_of\_Reviews\_Reviewer\_Has\_Given|Review|How many reviews this guest has written on Booking.com|43|Whole number|-|
|Reviewer\_Score|Review|Score this guest gave|7.5|Decimal number|Lowest possible score? Check later in SQL. Minimum score is 2.5 (check 8)|
|Tags|Review|Trip type, group type, room type, nights, device|\[' Leisure trip ', ' Couple ', ' Duplex Double Room ', ' Stayed 1 night ', 'Submitted from a mobile device']|Text|Looks like a list but it is one text string. Tags vary per review. Number of nights is inside the text.|
|days\_since\_review|Review|Days between review and data collection (2017)|625 day|Text|Not used; derived from Review\_Date if needed.|
|lat|Hotel|Latitude (north-south position)|523605759|Decimal number|Excel removed the decimal point. CHECK: missing values?|
|lng|Hotel|Longitude (east-west position)|523605759|Decimal number|Excel removed the decimal point. CHECK: missing values?|
|nationality\_group|Review (one value per review)|Reviewer nationality grouped for analysis: the 18 nationalities with at least 500 reviews keep their name; all others = 'Other'; NULL = 'Uknown'|United Kingdom / Other / Uknown|NVARCHAR(50)|'Other' is a mixed group (161) nationalities and must not be read as one market. Created in cleaning, Step 6. See decision log 9 Nov 2026.|





17 columns

one row = one review

text split into negative\_review and positive\_review



**CLEAN TABLE**

|**COLUMN NAME**|**DATA TYPE**|**LEVEL**|**WHAT IT MEANS**|**CREATED FROM**|**NOTES**|
|-|-|-|-|-|-|
|review\_id|INT|Review|Unique number per review|New (Step 1 - 04\_data\_cleaning\_sql)|Has 12 gaps from removed duplicates (Step 2 - 04\_data\_cleaning\_sql)|
|hotel\_address|NVARCHAR(255)|Hotel|Street, number, postcode, city, country in one field|Hotel\_Address, trimmed (Step 4b), renamed (Step 7b)|Special characters missing in source. Use coordinates, not address, for matching (decision log 5 Nov)|
|hotel\_name|NVARCHAR(255)|Hotel|Name of the hotel|Hotel\_Name, trimmed (Step 4b), renamed (Step 7b)|Unique per hotel in Amsterdam (Checks 5a/5b). Special characters missing in source (e.g. “Fleming s”)|
|reviewer\_nationality|NVARCHAR(255)|Review|Nationality of the reviewer|Reviewer\_Nationality, trimmed (Step 4b), renamed (Step 7b)|179 nationalities + 69 NULL. Nationality ≠ country of residence|
|negative\_review|NVARCHAR(MAX)|Review|What the guest disliked|Negative\_Review, trimmed (Step 4b), “No Negative” → NULL (Step 5), renamed (Step 7b)|NULL = no complaint written (14,361 rows, 25.1%). Guest-written “nothing”/”none” kept as text.<br />Punctuation and special characters removed in the source data.|
|positive\_review|NVARCHAR(MAX)|Review|What the guest liked|Positive\_Review, trimmed (Step 4b), “No Positive” → NULL (Step 5), renamed (Step 7b)|NULL = no text written (3,827 rows, 6.7%).<br />Punctuation and special characters removed in the source data.|
|tags|NVARCHAR(MAX)|Review|Trip type, group type, room type, nights, device|Tags, trimmed (Step 4b), renamed (Step 7b)|One text string that looks like a list; tags vary per review|
|review\_date|DATE|Review|Date the review was written|Review\_Date converted from text, format 101 (Step 3a)|4 Aug 2015 – 3 Aug 2017|
|reviewer\_score|DECIMAL(3,1)|Review|Score the guest gave, 2.5–10|Reviewer\_Score converted from text (Step 3b)|Average 8.46; scores cluster high|
|average\_score|DECIMAL(3,1)|Hotel|Hotel’s average score on Booking.com|Average\_Score converted from text (Step 3c)|One value per hotel (Check 3c-4). Don’t average across review rows|
|lat\_num|DECIMAL(10,7)|Hotel|Latitude (north–south position) of the hotel|lat converted from text (Step 3d)|Range 52.29–52.40, all in Amsterdam (Check 3d-3)|
|lng\_num|DECIMAL(10,7)|Hotel|Longitude (east–west position) of the hotel|lng converted from text (Step 3e)|Range 4.82–5.00, all in Amsterdam (Check 3e-3)|
|total\_number\_of\_reviews|INT|Hotel|Total reviews the hotel had on Booking.com|Total\_Number\_of\_Reviews converted from text (Step 3f)|One value per hotel (Check 3f-4). Don’t sum across review rows|
|additional\_number\_of\_scoring|INT|Hotel|Guests who gave a score without writing a review|Additional\_Number\_of\_Scoring converted from text (Step 3g-1)|Don’t sum across review rows|
|reviews\_given\_by\_reviewer|INT|Review|How many reviews this guest has written on Booking.com|Total\_Number\_of\_Reviews\_Reviewer\_Has\_Given converted from text (Step 3h)|Possible use: do experienced reviewers rate differently?|
|nationality\_group|NVARCHAR|Review|18 nationalities with at least 500 reviews; others = ‘Other’; NULL = ‘Unknown’|New, from reviewer\_nationality (Step 6)|‘Other’ is a mixed group (161 nationalities): never read it as one market (decision log 9 Nov)|





**amsterdam\_hotels**

Description: one row per Amsterdam hotel (105 rows), created from amsterdam\_reviews\_clean in 05\_historic\_labels.sql (Step 3); labels added in Step 7.



|**column\_name**|**data\_type**|**description**|**allowed values / example**|**source**|
|-|-|-|-|-|
|hotel\_name|nvarchar(255)|Hotel name as in the dataset (join key to reviews and labels). Some names contain dataset spelling errors, kept unchanged so joins work.|Hotel Arena|amsterdam\_reviews\_clean|
|hotel\_address|nvarchar(255)|Full address as in the dataset|s Gravesandestraat 55 Oost 1092 AA Amsterdam Netherlands|amsterdam\_reviews\_clean|
|average\_score|decimal|Hotel’s average score on Booking.com at time of data collection|8.6|amsterdam\_reviews\_clean|
|total\_number\_of\_reviews|int|Total reviews of the hotel on Booking.com (all languages), not only reviews in this dataset|4,000|amsterdam\_reviews\_clean|
|lat\_num|decimal|Latitude of the hotel|52.36|amsterdam\_reviews\_clean|
|lng\_num|decimal|Longitude of the hotel|4.92|amsterdam\_reviews\_clean|
|reviews\_in\_dataset|int|Number of reviews of this hotel in amsterdam\_reviews\_clean|489|Calculated: COUNT(\*) per hotel|
|label|nvarchar(20)|Whether the hotel is historic according to the project definition|historic; other|historic\_labels.xlsx via historic\_labels\_raw (Step 7b)|
|criteria\_met|nvarchar(20)|Which historic criteria the hotel meets (1 building, 2 events or people, 3 objects and interior, 4 practices, 5 hotel since 1917 or earlier). Text list, not a number.|none; 1; 1, 3; 1, 2, 3, 5|historic\_labels.xlsx via historic\_labels\_raw|
|location\_area|nvarchar(20)|"centre" or "outside". Centre = hotel\_address contains "Amsterdam City Center" (Booking.com district). Added 19 Nov 2026 (07\_analysis.sql, Step 9c). 45 centre, 60 outside|centre|Location check (Step 8g): compare historic and non-historic hotels in the same area. Power BI needs it as a column for charts and slicers, not only as a WHERE filter|
|hotel\_display\_name (Power BI only)|text|Copy of hotel\_name with special characters restored for display (Amrâth, Swissôtel, Estherea, De L'Europe, art'otel). Created in Power Query 23 Nov 2026. Used on chart axes only; hotel\_name stays the key|Grand Hotel Amrâth Amsterdam|The Kaggle source removed special characters, so names like "Amr th" looked like typos on the dashboard. hotel\_name stays unchanged because it is the key linking hotels to reviews|



**historic\_labels\_raw**

Description: import of the final hotel labels (105 rows). Source file data/clean/historic\_labels\_final.txt, exported from historic\_labels.xlsx on 16 Nov 2026. Raw table: not used directly in analysis; labels are copied into amsterdam\_hotels.



|**column\_name**|**data\_type**|**description**|**allowed\_values / example**|**source**|
|-|-|-|-|-|
|hotel\_name|nvarchar(255)|Hotel name, identical to amsterdam\_hotels.hotel\_name|Hotel Arena|historic\_labels.xlsx|
|label|nvarchar(50)|historic or other|historic; other|historic\_labels.xlsx|
|criteria\_met|nvarchar(50)|Criteria met, as a text list|none; 1, 3|historic\_labels.xlsx|



**keyword\_test\_log**



|**theme\_id**|**keyword**|**positive\_matches**|**issue**|**action**|**reason**|
|-|-|-|-|-|-|
|G1|check-in|0|technical zero: dataset has no hyphens (Check 2a)|remove|‘check in’ already in G1|
|G1|check-out|0|technical zero: dataset has no hyphens (Check 2a)|remove|‘check out’ already in G1|
|G9|old-fashioned|0|technical zero: dataset has no hyphens (Check 2a)|remove|‘old fashioned’ already in G9|
|H4|old-world|0|technical zero: dataset has no hyphens (Check 2a)|remove|‘old world’ already in H4|
|G9|run-down|0|technical zero: dataset has no hyphens (Check 2a)|remove|‘run down’ already in G9|
|H7|one-of-a-kind|0|technical zero: dataset has no hyphens (Check 2a)|remove|‘one of a kind’ already in H7|
|H3|bed-in|0|technical zero: dataset has no hyphens (Check 2a)|remove|‘bed in’ without a hyphen would match ‘comfortable bed in the room’|
|G2|wi-fi|0|technical zero: dataset has no hyphens (Check 2a)|change to ‘wi fi’|hyphen probably became a space; ‘wifi’ already in G2|
|H7|unique|223|suspect: may describe location or city ('unique location')|test; Check 2d: only 2 of 223 matches are 'unique location'; Check 2c: also used for modern design hotels (Fletcher, Student Hotel, citizenM), so interpret H7 via historic vs other comparison|check how many matches are 'unique location'|
|H7|boutique|207|suspect: hotel-name trap (2 hotel names contain 'Boutique')|keep	Check 2b: top 5 hotels have no 'boutique' in name (all historic); Notting Hill only 10 of 207 matches|check matches per hotel to H7 I|
|various|30 keywords (see list below)|0|language zero: 0 matches in both texts|keep|harmless (cannot change results); may match in other data (Project 3); G3 phrases kept as safety net for the location trap|
||historic district; history of the city; looks dated; former warehouse; former factory; merchant house; former church; former bank; former library; former hospital; former school; period furniture; dating back; centuries; Beatles; celebrities; since 18; famous guests; grand old hotel; another era; historic atmosphere; authentic atmosphere; bygone; Dutch culture; Dutch heritage; local culture; Dutch charm; wine cellar; tour of the building; unlike chain; different from other; not a chain|||||
|H1|whole theme|-|sample 20 random positive matches: 17 of 20 correct (85%)|keep theme|precision above 80%; errors: modern architecture (1), neighbouring building (1), hotel name 'Banks Mansion' (1)|
|H1|mansion|9|confirmed hotel-name trap: the Banks Mansion review matched only on the name|remove|low count, real noise|
|H1|architecture|88|1 of 6 sampled matches is modern architecture|keep|conservative error: modern-architecture mentions fall mostly in ‘other’ hotels, so they make the historic vs other difference smaller, not larger|
|H3|whole theme|-|sample of 20 random positive matches: 12 of 20 correct (60%)|fix keywords|below 80%; 6 of 8 errors from 3 keywords; estimated about 86% after the fix|
|H3|years old|15|confirmed: children’s ages (‘our 3 years old son’)|remove|2 errors in sample; families use it often|
|H3|famous|31|confirmed: nearby places (‘famous attractions’, ‘famous restaurant’)|remove|2 errors in sample; rarely about the hotel’s history|
|H3|century|18|confirmed: modern or area use (‘21st century’, ‘17th century canal ring’)	replace with ‘century old;|replace with ‘century old; century building; century house’|phrases keep the building’s age, drop other uses|
|H2|whole theme|-|sample of 20 random positive matches: 4 of 20 correct (20%)|fix keywords, then re-test|far below 80%; 15 of 16 errors from 3 keywords|
|H2|fireplace|32|confirmed: mostly modern hotels (Urban Lodge 7 of 20 sample reviews)|remove|8 errors in sample|
|H2|artwork|28|confirmed: art hotels and modern decor|remove|6 errors in sample|
|H2|art collection|2|same problem as artwork|remove|consistency with artwork decision|
|H2|tiles|4|confirmed: contains trap (‘detiles’); also modern bathrooms|remove|‘delft’ covers historic tiles|
|H4|whole theme|-|sample of 20 random positive matches: 9 of 20 correct (45%)|fix keyword|below 80%; estimated about 86% after removing ‘character'|
|H4|character|100|confirmed: means ‘personality’ (hotels, rooms, a barman); also modern hotels (citizenM)|remove|13 of 20 sample matches, only 3 correct (and those also mention ‘history’, so H3 still catches them)|
|H5|whole theme|-|sample of 20 random positive matches: 5 of 20 correct (25%)|decide at v1.0: option B (merge style words into H1)|15 errors, mostly location; correct matches all describe building style|
|H5|old Amsterdam; real Amsterdam; Amsterdam feel; local feel; like a local; very Amsterdam|-|confirmed: describe the area or vibe, not the hotel (old Amsterdam also a cheese)|remove|12 of 15 errors in sample|
|H6|whole theme|-|sample of 20 random positive matches: 19 of 20 correct (95%)|keep theme as is|above 80%; only error: library outside the hotel; hotel-name traps (courtyard, garden) not seen in sample|
|H7|whole theme|-|sample of 20 random positive matches: 17 of 20 correct (85%)|keep theme, remove 'memorable'|above 80%; errors: hotel name ‘Boutique Hotel Notting Hill’ (1), ‘memorable’ about staff or occasion (2)|
|H7|memorable|59|confirmed: describes service or the occasion (‘staff made our stay memorable’), not distinctiveness|remove|2 of 3 sampled matches wrong; measures satisfaction, not uniqueness|
|G3|whole theme|-|sample of 20 random positive matches: 20 of 20 correct (100%)|keep theme|‘near’ used for ‘near the window’ once, but the review also mentioned the metro, so still location|
|G3|old Amsterdam; real Amsterdam; Amsterdam feel; local feel; like a local; very Amsterdam|-|location phrases removed from H5 (sample 5e)|add to G3|location praise must be counted as location, not lost; historic hotels’ guests use these phrases|
|G7|whole theme|-|sample of 20 random positive matches: 18 of 20 correct (90%)|keep theme|above 80%; quiet location and quiet street counted as noise topic (overlap with G3 is fine)|
|G7|quiet|2,474|errors: typo for ‘quite’ (‘quiet good’) (1); ‘not busy’ meaning (‘quiet bar’) (1)|keep|18 of 20 correct; without it G7 misses most positive noise mentions; ‘quite’ typos may be more common among non-native English writers (note for the nationality analysis)|
|G9|whole theme|-|sample of 20 random positive matches: 17 of 20 about condition (85%)|keep theme; rename to ‘Condition and signs of age’ at v1.0|in positive text G9 mostly means renovation praise; topic is condition, opinion comes from the column|
|G9|maintenance|21|confirmed: maintenance staff (‘maintenance team responded quickly’)|remove|2 errors in sample; about staff (G1), not condition|
|G9|rust|16|confirmed: contains trap (‘frustrated’)|replace with ‘rusty’|also matches 'trust'|
|G9|dated room|7|contains trap: ‘updated room’|keep, noted|still about condition, so harmless here|
|H1|whole theme v1.0|-|re-test after merge: 11 of 20 correct (55%)|remove 5 keywords, then freeze|combined with sample 5a and excluding the removed words: 28 of 34 = 82%|
|H1|diamond factory|2|confirmed: tourist attractions nearby (Gassan, Coster)|remove|2 errors in sample 7a|
|H1|Dutch house; Dutch style; typical Dutch|-|confirmed: music genre (‘dutch house parties’), service (‘Dutch style customer service’), comparison (‘typical Dutch hotel rooms’)|remove|3 errors in sample 7a|
|H1|architecture|88|modern architecture in 3 of 40 sampled reviews (incl. one historic hotel)|keep, known limitation|still mostly correct; record as limitation|



**dbo.themes**

|**table\_name**|**column\_name**|**data\_type**|**description**|**example**|
|-|-|-|-|-|
|themes|theme\_id|nvarchar(10)|Theme code; links to review\_theme\_matches.theme\_id. 14 themes (H2 and H5 merged into H1, IDs not renumbered)|H1|
|themes|theme|nvarchar(100)|Full theme name for charts|Historic building, architecture and interior|
|themes|theme\_group|nvarchar(20)|Heritage (H themes) or General (G themes)|Heritage|
|themes|report\_category|nvarchar(50)|Reporting group combining themes: Heritage experience, Comfort and condition, Service, Location, Food, Value, Cleanliness, Accessibility|Heritage experience|
|themes|definition|nvarchar(500)|What the theme covers (from theme\_dictionary\_v1.0.xlsx); for tooltips|The building itself: architecture, facade, original features, period interior|



