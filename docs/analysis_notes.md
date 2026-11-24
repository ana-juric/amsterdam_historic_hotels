# Analysis notes: Guest experience in historic hotels (Amsterdam)

Research question: What do guests praise and criticise in historic hotels compared with
other hotels in Amsterdam, and which nationalities value heritage most?

Data: 57,202 Booking.com reviews (Kaggle 515K, Amsterdam only) from 4 August 2015 to 3 August 2017; 
49 historic and 56 other hotels.
Group sizes: historic 23,962 reviews, other (non-historic) 33,240 reviews.
Wording: "non-historic hotels" = hotels labelled "other" (not "modern": some are in old buildings).

---

## Stage 4: Theme dictionary (keyword testing, 15-17 Nov 2026)

- Heritage themes are rare in reviews compared with general themes (location, staff, room).
- H5 (merged into H1 in v1.0): guests link Dutch identity mostly to the location, not the hotel.
  Thesis link: Antonio.
- "quiet" is sometimes written for "quite" (typo). Possible nationality bias (non-native writers).
- H1 sample (Step 5a) came mostly from historic hotels.
- Precision samples: H1 82% (combined 28/34), H3 60%, H4 45%, H6 95%, H7 85%, G3 100%, G7 90%, G9 85%.
  Lowest precision: H3 (history) and H4 (atmosphere).
- Known limitations: "architecture" sometimes refers to modern design; one London review under Ramada;
  "quiet" for "quite".

---

## Stage 5: Analysis (07_analysis.sql)

### 18 Nov 2026: Step 2, match table coverage
- 85.6% of all reviews mention at least one theme in the positive text, 59.3% in the negative text.
- Of reviews that HAVE text: 92% positive (48,938 of 53,375), 79% negative (33,916 of 42,841).

### 18 Nov 2026: Step 3, review scores
- Average score historic 8.53 vs non-historic 8.40 (+0.13).

### 18 Nov 2026: Step 4b, praise per theme
Source: % of all reviews in each group (historic 23,962 / non-historic 33,240) that praise the theme.

1. Guests notice heritage. Heritage themes are praised far more often in historic hotels:
   H3 story 0.76% vs 0.08% (about 10x), H1 building 1.23% vs 0.14% (about 9x),
   H4 atmosphere 0.25% vs 0.04% (about 7x), H7 uniqueness 1.17% vs 0.51% (about 2x).
   This also supports the labelling: hotels labelled historic are the ones guests describe as historic.
2. Heritage is rare. Only about 1 in 100 historic reviews praises the building.
   Guests write mostly about location, staff and the room.
   Fits the thesis: heritage as background to the experience, not the main topic.
3. H6 spaces and experiences: no difference (2.09% vs 2.19%).
   Bars, gardens and lounges are praised equally, so the theme is not specific to heritage.
4. Trade-off: historic hotels are praised more for location (51.56% vs 38.90%, +12.7 points)
   and staff (46.78% vs 42.34%, +4.4), but less for cleanliness (11.11% vs 18.44%, -7.3)
   and rooms (42.33% vs 49.44%, -7.1).
5. Cautions:
   - Location is the biggest difference: historic hotels may score higher partly because
     of where they are (confounding; G3 is the control theme). Checked in Step 8g.
   - Small numbers: H4 rests on 60 historic and 12 non-historic reviews.

### 18 Nov 2026: Step 5, criticism per theme
Source: % of all reviews in each group that criticise the theme (negative text).

Heritage themes
- Heritage is criticised more often in historic hotels, but criticism stays very small (all below 1%).
  H1 building: 0.37% vs 0.08% (about 89 vs 27 reviews).
- Most likely reason: the topic only exists in historic hotels, so guests write about it more,
  both positively and negatively.
- Praise clearly outweighs criticism: H1 in historic hotels is praised 1.23% and criticised 0.37%,
  more than 3 praising reviews for every critical one.
- H3 (0.16% vs 0.08%) and H7 (0.13% vs 0.08%) rest on about 30-40 reviews per group, too few to
  interpret. H3 keyword precision was only 60%.
  Hypothesis for later: high expectations set by the hotel's own heritage story (not testable with this data).

General themes: historic hotels criticised more
- G7 noise: 8.03% vs 3.97% (2x). Possibly central location and older construction (windows, walls).
- G9 condition and signs of age: 3.66% vs 1.83% (2x). Guests notice wear more often in old buildings.
- G8 stairs and lift: 4.41% vs 2.77%. Possibly steep stairs and missing lifts in old buildings.
- G2 room, comfort and facilities: 39.18% vs 34.16% (+5 points). Possibly smaller rooms in old buildings.

General themes: historic hotels criticised less
- G3 location: 5.08% vs 12.72%, about 60% less. Historic hotels are mostly in the centre.
- G5 breakfast and food: 14.49% vs 17.01%.

About equal: G1 staff, G4 cleanliness, G6 price.
- Cleanliness: criticism is equal, but praise was lower in historic hotels (11.11% vs 18.44%).
  Historic hotels are not dirtier; cleanliness is praised more in non-historic hotels.

Overall picture: historic hotels trade location and heritage character for noise, wear,
stairs and room comfort. These are the typical costs of an old building in a city centre.

### 18 Nov 2026: G7 noise, top keywords in criticism (practice query)
- noisy 1,278, noise 1,142, loud 423, construction 362, quiet 261.
- "construction" = temporary building works, not related to the building's age.
  Possible bias in G7 (historic vs non-historic) if works were near some historic hotels.
- "quiet" in negative text = "not quiet" or the "quite" typo (known limitation).

### 18 Nov 2026: Step 6, heritage overall (all H themes)
- About 1 in 20 historic reviews praises heritage (4.97%) vs about 1 in 34 non-historic reviews (2.90%):
  1.7x more, +2.07 percentage points.
- Heritage is also criticised more in historic hotels (1.52% vs 1.02%): the topic exists there,
  so guests write about it in both directions.
- The tone is similar: about 3.3 praising reviews per critical one in historic hotels, 2.8 in non-historic.
- Non-historic hotels' heritage share comes mostly from H6 (spaces and experiences), which is not
  heritage-specific. Checked in Step 8a (core heritage without H6).

### 18 Nov 2026: Step 7, nationalities (all H themes)

Step 7a: group sizes (reviews in historic hotels)
- 20 groups, sum 23,962. Largest: UK 9,296; Other 4,299; USA 2,817; Ireland 1,137; Australia 1,031.
- "Other" = mixed group of many countries, not a nationality. "Unknown" = 19 reviews.

Step 7b: decision
- Excluded "Other" and "Unknown". Minimum 500 reviews in historic hotels, set before seeing results.
- Reason: at about 5% heritage praise, margin of error is about +/-1.9 points at 500 reviews (+/-2.5 at 300).
- 8 nationalities included: UK, USA, Ireland, Australia, Israel, UAE, Netherlands, Canada.

Step 7c: heritage praise per nationality (any H theme, positive, % of historic reviews)
- Canada 9.23% (509 reviews, range 6.7-11.7)
- USA 8.20% (2,817, range 7.2-9.2)
- Australia 7.47% (1,031, range 5.9-9.1)
- Netherlands 6.36% (550, range 4.3-8.4)
- UK 4.22% (9,296, range 3.8-4.6)
- UAE 3.59% (557, range 2.1-5.1)
- Ireland 3.34% (1,137, range 2.3-4.4)
- Israel 2.81% (640, range 1.5-4.1)

Findings
- Guests from North America and Australia praise heritage about twice as often as guests from
  the UK and Ireland. USA vs UK ranges do not overlap, so this is not chance.
- The exact ranking among Canada, USA and Australia is not reliable (ranges overlap).

Possible explanation (hypothesis)
- Old European buildings are more of a novelty for guests from countries with fewer very old buildings.
  Thesis link: heritage experienced through contrast with home.

Cautions
- Measures how often guests write about heritage, not how much they value it.
- English keywords: guests writing in a second language (UAE, Israel, Netherlands) may be underestimated.
- Nationalities may choose different hotels: part of the difference may come from the hotel, not the guest.

### 19 Nov 2026: Step 8a, core heritage (H1, H3, H4, H7, without H6)
- Core heritage praised in 3.09% of historic reviews vs 0.75% of non-historic reviews
  (about 4x; about 1 in 32 vs 1 in 133).
- With H6 included (Step 6) the gap was only 1.7x: H6 blurs the difference.
- Tone: 4.8 praising reviews per critical one in historic hotels vs 2.9 in non-historic.
- Headline number for the project: core heritage, not all H themes.

### 19 Nov 2026: Step 8b-8c, core heritage per historic hotel
- Heritage praise is spread: 36 of 49 historic hotels above the non-historic average (0.75%);
  with 100+ reviews: 33 of 46 (so 13 of 46 at or below the non-historic level).
- Highest reliable: Amrath 14.3%, Canal House 12.5% (name trap, see 8e), Pulitzer 10.0%,
  Arena 8.6%, Ambassade 8.4%.
- Small hotels unreliable: Seven One Seven (17 reviews), InterContinental (34).
- Lowest: large chain hotels in listed buildings (NH Carlton, Krasnapolsky, Radisson, Swissotel, Hilton),
  near non-historic level.
  Hypothesis: heritage not visible or communicated. Thesis link: building alone is not an experiencescape.
  Management message: a listed building is not enough, guests must experience it.

### 19 Nov 2026: Step 8e, Canal House name trap
- In all 9 Canal House reviews containing "canal house", it is the hotel's name, not the building.
- Canal House core heritage between 7.6% and 12.5%; effect on the overall result negligible
  (3.09% -> at least 3.05%). Logged as limitation; dictionary not changed (frozen v1.0).

### 19 Nov 2026: Step 8f-8g, location check
- City centre = Booking district "Amsterdam City Center": 34 historic and 11 non-historic hotels.
- Location and heritage strongly linked: 69% of historic vs 20% of non-historic hotels are central.
- Centre only: average score historic 8.58 vs non-historic 8.48 (gap 0.10; all hotels: 0.13).
  Location explains only a small part of the score difference.
- Caution: only 11 non-historic hotels in the centre.

### 23 Nov 2026: Step 8h, core heritage per nationality (robustness)
- Pattern holds without H6: USA 5.40% vs UK 2.57% (2.1x; with H6: 1.9x).
- Canada 6.09%, USA 5.40%, Australia 4.85%, Netherlands 4.73%, UK 2.57%, Ireland 2.37%,
  UAE 2.33%, Israel 1.72%.
- Margins of error (95%): USA 4.6-6.2 vs UK 2.3-2.9, no overlap.
- Netherlands 4.73%, close to Australia (4.85%), probably above UK (margin 3.0-6.5).
- Dashboard Page 3 uses these core heritage figures.

---

## Key findings (Step 9a, 19 Nov 2026)
Data: 57,202 Booking.com reviews (4 August 2015 – 3 August 2017); 49 historic and 56 non-historic hotels.
Percentages = share of all reviews in the group.

1. Guests notice heritage, and praise it far more often in historic hotels.
   Core heritage (building, interior, history, atmosphere, uniqueness) is praised in 3.09%
   of historic reviews vs 0.75% of non-historic reviews: about 4 times more (1 in 32 vs 1 in 133).
   Praise clearly outweighs criticism: 4.8 praising reviews per critical one (non-historic: 2.9).

2. But heritage is a small topic. In both groups guests mostly praise location, staff and the room
   (40-50% of reviews each).

3. Historic hotels win on location and staff, and lose on comfort and condition.
   Praised more: location 51.6% vs 38.9%, staff 46.8% vs 42.3%.
   Praised less: cleanliness 11.1% vs 18.4%, room 42.3% vs 49.4%.
   Criticised more: noise 8.0% vs 4.0%, condition and signs of age 3.7% vs 1.8%,
   stairs and lift 4.4% vs 2.8%, room 39.2% vs 34.2%.
   Possibly: older buildings in a busy city centre.

4. Historic hotels score slightly higher, and not only because of location.
   Average score 8.53 vs 8.40; in the city centre only, 8.58 vs 8.48.

5. A historic building is not enough. Heritage praise is spread across most historic hotels,
   but 13 of 46 historic hotels (100+ reviews) are at or below the non-historic level,
   mostly large chain hotels in listed buildings (e.g. NH Carlton, Krasnapolsky, Radisson).
   Possibly the heritage is not visible or communicated.

6. Guests from North America, Australia and the Netherlands praise heritage about twice as often
   as guests from the UK and Ireland (core heritage, historic hotels: USA 5.4%, Canada 6.1%,
   Australia 4.9%, Netherlands 4.7% vs UK 2.6%, Ireland 2.4%).
   The exact ranking among the top group is not reliable.
   Possibly: old European buildings are more of a novelty for them.

Cautions
- Keyword method: English keywords, precision 45-100% per theme (lowest: H4 atmosphere, H3 history).
- We measure how often guests write about a topic, not how much they value it.
- Small groups: only 11 non-historic hotels in the city centre; nationalities limited to 500+ reviews.

---

## Idea for future work
Do historic hotels that communicate their heritage (website, story, interior) get more heritage praise?
Method: code each historic hotel's website (heritage mentioned: yes/no/strongly), compare with core heritage %.
Link to thesis: website analysis of historic hotels (2019).
