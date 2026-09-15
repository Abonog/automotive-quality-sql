-- ============================================================
-- Cleaning step 5 (the hard one): parse inspection_date despite
-- 4 different mixed formats in the same column.
--
-- Approach: detect which format a value is in via REGEXP pattern
-- matching on its shape, then parse it with the matching
-- STR_TO_DATE() format string.
--
-- Run against: data/quality_raw_practice_mysql.sql
-- ============================================================

SELECT
    inspection_date,
    CASE
        -- ISO: 2026-01-16  -> 4 digits, dash, 2 digits, dash, 2 digits
        WHEN inspection_date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN STR_TO_DATE(inspection_date, '%Y-%m-%d')

        -- EU: 16-01-2026  -> 2 digits, dash, 2 digits, dash, 4 digits
        -- (same separator as ISO -- distinguished only by which side
        -- has the 4-digit group)
        WHEN inspection_date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
            THEN STR_TO_DATE(inspection_date, '%d-%m-%Y')

        -- US: 01/22/2026  -> 2 digits, slash, 2 digits, slash, 4 digits
        WHEN inspection_date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
            THEN STR_TO_DATE(inspection_date, '%m/%d/%Y')

        -- Text: Jan 19, 2026  -> 3-letter month, space, 1-2 digits, comma, space, 4 digits
        WHEN inspection_date REGEXP '^[A-Za-z]{3} [0-9]{1,2}, [0-9]{4}$'
            THEN STR_TO_DATE(inspection_date, '%b %d, %Y')

        ELSE NULL  -- genuinely blank inspection_date values; can't be parsed
    END AS real_inspection_date
FROM raw_inspections;

-- Result: 76 rows in, 73 parsed correctly into real dates, 3 returned
-- NULL -- exactly the 3 rows where inspection_date was blank to begin
-- with. No date silently mis-parsed into the wrong shape.
