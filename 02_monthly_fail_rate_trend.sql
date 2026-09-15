-- ============================================================
-- Monthly fail-rate trend: is overall quality getting better or
-- worse over time?
--
-- Run against: data/quality_practice_mysql.sql
-- ============================================================

SELECT
    MONTH(insp.inspection_date) AS month,
    COUNT(*) AS total_inspections,
    SUM(CASE WHEN insp.result = 'Fail' THEN 1 ELSE 0 END) AS fail_count,
    ROUND(
        100.0 * SUM(CASE WHEN insp.result = 'Fail' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS overall_failure_rate_pct
FROM inspections AS insp
GROUP BY month
ORDER BY month ASC;   -- chronological order matters here: sorting by
                       -- rate instead of by month would hide the trend
                       -- this query exists to show

-- Result on this dataset (Jan-Jun 2026):
--   Jan  11.8%
--   Feb  13.0%
--   Mar  17.2%
--   Apr  23.8%   <- peak
--   May   4.8%   <- sharp drop
--   Jun   5.0%
--
-- Fail rate climbed steadily from January through a peak in April,
-- then dropped sharply and stayed low through June. That pattern is
-- exactly the kind of thing SQL is good at surfacing but can't
-- explain on its own -- the natural next question is what changed
-- between April and May (a supplier corrective action? a process
-- change? a different inspector rotation?), which is a root-cause
-- question for the business, not a query.
