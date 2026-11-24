# Data source log

Project 1: Guest experience in historic hotels (Amsterdam)

---

## 1. Main dataset

| Field | Value |
|---|---|
| Name | 515K Hotel Reviews Data in Europe |
| URL | https://www.kaggle.com/datasets/jiashenliu/515k-hotel-reviews-data-in-europe |
| Author | Jiashen Liu |
| Licence | CC0: Public Domain |
| Original source | Reviews collected from Booking.com by the dataset's author |
| Review period | 4 August 2015 to 3 August 2017 (checked in SQL, 07_analysis.sql, Check 9d) |
| Downloaded | 4 Nov 2026 |

### Notes

1. **Amsterdam hotels:** 107 distinct Hotel_Address values containing "Amsterdam" in the raw data;
   105 hotels in the final dataset (amsterdam_hotels) after cleaning. See the decision log for the
   difference.
2. **Amsterdam hotel with the most reviews:** Hotel Estheréa (shown as "Hotel Esther a" because of
   missing special characters; see Data issues).
   Method: pivot table with Hotel_Name in Rows and Count of Hotel_Address in Values, filtered to
   addresses containing "Amsterdam", sorted largest to smallest.
   Note: this counts reviews per hotel, not unique values.

### Data issues

| Issue | Where | Cause | Fix | Status |
|---|---|---|---|---|
| Special characters missing (é in "Estheréa", â in "Amrâth", ô in "Swissôtel") | Hotel_Name, review text | Removed by the dataset's author | Names restored for display in Power BI only (hotel_display_name, 23 Nov 2026); hotel_name kept as key; keywords adapted | Resolved for display; review text unchanged (see limitations log) |

---

## 2. Sources for labelling historic hotels

| Source | Link | Used for | Checked | Notes |
|---|---|---|---|---|
| Amsterdam monument map (Gemeente Amsterdam) | https://maps.amsterdam.nl/monumenten/ | Checking whether hotel buildings are municipal or national monuments; build year, architect, original function | 13 Nov 2026 | Official municipal source; shows both municipal and national monuments (rijksmonumenten). Structured fields sometimes conflict with descriptions; the description was used. |
| Official hotel websites | See source column in historic_labels_clean.xlsx | Documented historic facts per hotel | 12-13 Nov 2026 | Marketing sources: only specific, checkable facts accepted |
| Hotel press release (Jan Luyken), via TravelDailyNews | https://www.traveldailynews.com/hotels-lodging/new-boutique-townhouse-in-amsterdam-is-now-open/ | Build year and architect of Bilderberg Hotel Jan Luyken | 13 Nov 2026 | Accepted under widened source rule (hotel's own communication) |
