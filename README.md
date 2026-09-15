# Automotive Quality Data — SQL Analysis & Data Cleaning

A SQL project built on realistic (synthetic) automotive manufacturing quality data — supplier inspections and defects — approached the way a quality data analyst would: not just querying data, but first establishing whether it can be trusted at all.

I currently work as a Quality Engineer in the automotive industry. This project is where that background meets SQL: the questions asked here (which supplier is underperforming, is quality trending up or down, what's the most common failure mode) are the same questions I ask at work — this is the version answered with queries instead of manual review.

## Contents

- **`data/quality_practice_mysql.sql`** — a clean relational dataset (suppliers → parts → production batches → inspections → defects) used for the analysis queries.
- **`data/quality_raw_practice_mysql.sql`** — a single, deliberately messy inspections table used for the data-cleaning exercises.
- **`sql/01–03`** — analysis queries against the clean dataset.
- **`sql/04–08`** — data-cleaning queries against the messy dataset, one per issue category.

## Part 1 — Analysis

**Which supplier is underperforming?** ([`01_supplier_fail_rate.sql`](sql/01_supplier_fail_rate.sql)) — Fail rate by supplier, using joins across four tables and conditional aggregation. GammaPlastics fails at 31.6%, roughly 3x the rate of the best-performing supplier (BetaCast, 4.8%) — a gap large enough to be a real signal, not noise.

**Is quality improving or getting worse over time?** ([`02_monthly_fail_rate_trend.sql`](sql/02_monthly_fail_rate_trend.sql)) — Monthly fail rate, Jan–Jun. Fail rate climbed steadily from 11.8% in January to a peak of 23.8% in April, then dropped sharply to under 5% in May and stayed there. SQL surfaces the pattern; it doesn't explain it — the natural next question is what changed between April and May.

**What fails most often, and how severely?** ([`03_top_defect_types.sql`](sql/03_top_defect_types.sql)) — Top 5 defect types by frequency, each paired with its most common severity level, using `PARTITION BY` / `ROW_NUMBER()` window functions. Notably, at least one defect type turned out to have all its severity levels tied at the same count — there is no genuine single "most common severity" for it, only a tiebreak, which the query documents rather than hides.

## Part 2 — Data cleaning

The raw inspections table has 76 rows and looks clean at a glance — it isn't. Mapped to the standard dimensions of data quality:

| Dimension | Issue found | Query |
|---|---|---|
| Uniqueness | 6 pairs of exact duplicate rows (likely double data entry) | [`04_cleaning_deduplication.sql`](sql/04_cleaning_deduplication.sql) |
| Consistency | `supplier_name` alone had 45 distinct spellings for 6 real suppliers (case, whitespace); dates mixed 4 different formats | [`05_cleaning_standardize_supplier_name.sql`](sql/05_cleaning_standardize_supplier_name.sql), [`08_cleaning_multi_format_date_parsing.sql`](sql/08_cleaning_multi_format_date_parsing.sql) |
| Completeness | 22 rows missing key fields — mostly placeholder text (`'N/A'`, `'unknown'`, `'-'`) rather than true NULLs | [`06_cleaning_missing_value_completeness.sql`](sql/06_cleaning_missing_value_completeness.sql) |
| Validity | 11 rows with a physically impossible defect count (negative, or exceeding units inspected) | [`07_cleaning_invalid_quantity_flags.sql`](sql/07_cleaning_invalid_quantity_flags.sql) |

## Lessons that came out of building this

A few things worth writing down, because they came from real bugs caught along the way rather than from a tutorial:

- **String comparisons should be normalized explicitly, not left to database defaults.** A `CASE WHEN status = 'fail'` against data stored as `'Fail'` returns silently wrong results (all-zero) on a case-sensitive engine, and "works" on a case-insensitive one only because of a collation setting nobody chose on purpose.
- **A rate is only meaningful if the numerator and denominator share units.** Dividing a count of failed inspections by total units produced (instead of total inspections) still runs and returns a number — just a meaningless one.
- **Window functions run *after* `GROUP BY`.** `COUNT(*) OVER (PARTITION BY x)` on a grouped result counts grouped rows, not the original raw rows underneath them — `SUM(COUNT(*)) OVER (...)` is what reconstructs the true total.
- **Ties are real and worth surfacing, not hiding.** A `LIMIT` or `ROW_NUMBER()` ranking will pick an answer even when the underlying data has a genuine tie — an explicit tiebreaker (and a note about it) is more honest than a silently arbitrary result.

## Tech

MySQL 8 (window functions, `REGEXP`, `STR_TO_DATE`). To run: load either `.sql` file in `data/` into MySQL, then run any query in `sql/` against it.
