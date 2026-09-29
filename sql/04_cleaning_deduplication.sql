-- ============================================================
-- Cleaning step 1: remove exact duplicate rows (same content,
-- different row_id -- likely double data entry).
--
-- Run against: data/quality_raw_practice_mysql.sql
-- ============================================================

-- Preview first: always confirm exactly what a DELETE will remove
-- before running it, since a DELETE can't be undone by re-querying.
SELECT row_id FROM (
    SELECT
        row_id,
        ROW_NUMBER() OVER (
            PARTITION BY
                part_number, supplier_name, plant, inspection_date,
                inspector_name, defect_type, severity,
                quantity_inspected, quantity_defective, shift
            ORDER BY row_id
        ) AS row_num
    FROM raw_inspections
) AS t
WHERE row_num > 1;

-- Then delete. Wrapping the ROW_NUMBER() subquery in an extra derived
-- table (the "t" alias) is required in MySQL -- without it, you can't
-- reference the same table you're deleting from inside the subquery
-- directly ("You can't specify target table for update in FROM clause").
DELETE FROM raw_inspections
WHERE row_id IN (
    SELECT row_id FROM (
        SELECT
            row_id,
            ROW_NUMBER() OVER (
                PARTITION BY
                    part_number, supplier_name, plant, inspection_date,
                    inspector_name, defect_type, severity,
                    quantity_inspected, quantity_defective, shift
                ORDER BY row_id
            ) AS row_num
        FROM raw_inspections
    ) AS t
    WHERE row_num > 1
);

-- Result: 76 rows -> 70 rows (6 exact duplicates removed, keeping
-- the lowest row_id -- i.e. the first-entered copy -- of each pair).
