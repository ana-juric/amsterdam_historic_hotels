# Limitations log

Project 1: Guest experience in historic hotels (Amsterdam)

---

## 1. Data

- **Time period.** Reviews are from 4 August 2015 to 3 August 2017, before COVID. Hotels may have
  renovated, changed owner or changed service since then. Results describe guest experience at that
  time; the method can be applied to current reviews (Project 3).
- **Language and markets.** Reviews appear to be mainly in English, so English-speaking markets are
  over-represented (UK 40%) and markets such as Germany and the Netherlands under-represented
  compared with real visitor numbers. Results describe English-writing reviewers, not all guests.
- **Reviewer habits.** Review-writing habits differ between nationalities, so reviewers may not
  represent all guests of that nationality.
- **Missing characters.** Review text, hotel names and addresses have punctuation and special
  characters removed by the dataset creator (no hyphens or apostrophes; characters such as â, é and ö
  missing, e.g. "Hotel Esther a" for Estheréa). Exact text matching with other sources (e.g. the
  monument register) is unreliable. Keywords were adapted (no hyphens, no apostrophes). Hotel names
  were restored for display only in Power BI (hotel_display_name); hotel_name stays the key.
- **Tags.** Tags have spaces around each tag inside the list (e.g. ' Couple '); TRIM only removed
  spaces at the start and end of the whole value, so a search for an exact tag finds nothing.
  Use LIKE '%Couple%', or split tags into a separate table if needed.

---

## 2. Labelling historic hotels

- **Checked in 2026, reviews from 2015-2017.** Labels describe each hotel's building and history as
  checked in November 2026. Buildings rarely change, but some hotels have since closed or been
  rebranded (e.g. Pillows Anna van den Vondel, Holiday Inn Amsterdam, Amsterdam Canal Residence),
  and hotels may have presented their history differently in 2015-2017.
- **Labels depend on documentation.** A hotel in an old building without a listing or a specific
  fact in available sources is labelled "other", so the "other" (non-historic) group may still
  contain a few undocumented historic buildings, and the historic group may be slightly underestimated.
- **Hotel no longer operating: Pillows Anna van den Vondel.** It operated during the review period
  but no longer operates at its original address (checked 13 Nov 2026). The Pillows brand now runs a
  different hotel, Pillows Maurits at the Park (Mauritskade 61, opened 2022), in another building.
  The hotel's own website for the original location no longer exists and the building has no monument
  listing, so no historic fact could be documented; it is labelled "other". Its true status is uncertain.
- **Conflicting register fields.** On the Amsterdam monument map, structured fields (year, original
  function) sometimes conflict with the written description. In such cases the description was used.
- **Marketing sources.** Some evidence comes from the hotels' own marketing (official websites,
  press releases). Only specific, checkable facts were accepted, but dates there can be less reliable
  than register data (e.g. Hotel Roemer's "18th-century" claim).

---

## 3. Keyword method (theme dictionary v1.0)

- **Words, not meaning.** Keywords match words, not meaning. Precision per theme, tested on random
  samples, ranges from 45% (H4 atmosphere) to 100% (G3 location); H3 (history) was 60%.
- **"architecture"** sometimes refers to modern architecture (3 of 40 sampled H1 reviews, including
  one in a historic hotel); H1 may slightly overcount building praise.
- **"quiet" for "quite".** Some reviewers write "quiet" when they mean "quite"; this can add false
  matches to G7 (noise), possibly more for non-native writers.
- **Hotel-name trap (H1 keyword "canal house").** In 9 of Canal House's 23 core heritage reviews,
  "canal house" is the hotel's name, not a description of the building (manual reading, Step 8e).
  Canal House core heritage is therefore between 7.6% (14 of 184 reviews, if all 9 are removed) and
  12.5% (23 of 184, as measured). Effect on the overall result: at most 9 of 740 reviews, so 3.09%
  becomes at least 3.05%. Not corrected, because the dictionary was frozen before the analysis (v1.0).

---

## 4. Analysis and interpretation

- **Group sizes.** Historic hotels have fewer reviews per hotel (about 489 vs 594), and the two groups
  differ in size (23,962 vs 33,240 reviews), so results are compared as percentages, not raw counts.
- **Writing is not valuing.** The analysis measures how often guests write about a topic, not how much
  it matters to them.
- **Location.** 69% of historic but only 20% of non-historic hotels are in the city centre. The
  centre-only comparison (Step 8g) rests on only 11 non-historic hotels.
- **Nationalities.** Only nationalities with 500+ reviews in historic hotels are compared; the exact
  ranking within the top group (Canada, USA, Australia, Netherlands) is uncertain. Nationalities may
  also choose different hotels, so part of the difference may come from the hotels, not the guests.
- **Small hotels.** Hotels with fewer than 100 reviews (e.g. Seven One Seven, 17 reviews) give
  unreliable percentages and are excluded from the hotel-level dashboard chart.
