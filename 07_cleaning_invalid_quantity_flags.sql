-- ============================================================
-- Cleaning step 4: flag business-rule violations.
--
-- A negative defect count, or a defect count that exceeds the
-- number of units inspected, is physically impossible -- these are
-- validity errors, not formatting issues.
--
-- Run against: data/quality_raw_practice_mysql.sql
-- ============================================================

SELECT
    row_id,
    quantity_inspected,
    quantity_defective,
    CASE
        WHEN quantity_defective < 0 THEN 'Negative defective quantity'
        WHEN quantity_defective > quantity_inspected THEN 'Defective exceeds inspected'
        ELSE 'Valid'
    END AS business_rule_flag
FROM raw_inspections
WHERE quantity_defective < 0
   OR quantity_defective > quantity_inspected;

-- Result: 11 rows flagged -- 9 with a negative quantity_defective,
-- 2 where quantity_defective exceeds quantity_inspected. This query
-- flags rather than silently fixing or deleting: a real-world next
-- step here is going back to the source system or the inspector to
-- understand why, not guessing at a correction.
