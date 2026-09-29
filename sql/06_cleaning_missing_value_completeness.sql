-- ============================================================
-- Cleaning step 3: true completeness check.
--
-- Missing values in this data show up two ways: real NULLs, and
-- placeholder text standing in for missing data ('N/A', 'n/a',
-- 'NA', 'unknown', '-', ''). A naive `IS NULL` check misses the
-- second kind entirely -- which is most of it here.
--
-- Run against: data/quality_raw_practice_mysql.sql
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN supplier_name IS NULL
              OR LOWER(TRIM(supplier_name)) IN ('n/a', 'na', 'unknown', '-')
              OR TRIM(supplier_name) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_supplier_name,

    SUM(
        CASE
            WHEN inspector_name IS NULL
              OR LOWER(TRIM(inspector_name)) IN ('n/a', 'na', 'unknown', '-')
              OR TRIM(inspector_name) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_inspector_name,

    SUM(
        CASE
            WHEN defect_type IS NULL
              OR LOWER(TRIM(defect_type)) IN ('n/a', 'na', 'unknown', '-')
              OR TRIM(defect_type) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_defect_type
FROM raw_inspections;

-- Result: 9 missing supplier_name, 10 missing inspector_name,
-- 3 missing defect_type -- none of which are true SQL NULLs, so an
-- `IS NULL`-only check would have reported 0 missing values across
-- the board despite 22 rows genuinely being incomplete.
