-- ============================================================
-- Top 5 defect types by total occurrence, along with each type's
-- most common severity level.
--
-- Uses PARTITION BY / ROW_NUMBER() -- the standard "top N per
-- group" window-function pattern.
--
-- Run against: data/quality_practice_mysql.sql
-- ============================================================

SELECT
    defect_type,
    total_occurrences,
    severity,
    severity_count
FROM (
    SELECT
        defect_type,
        -- SUM(COUNT(*)) OVER (...), not COUNT(*) OVER (...):
        -- window functions run *after* GROUP BY, so COUNT(*) OVER(...)
        -- here would count grouped rows (i.e. how many distinct
        -- severities a defect type has), not the true total number
        -- of raw defect records for that type.
        SUM(COUNT(*)) OVER (PARTITION BY defect_type) AS total_occurrences,
        severity,
        COUNT(*) AS severity_count,
        ROW_NUMBER() OVER (
            PARTITION BY defect_type
            ORDER BY COUNT(*) DESC, severity ASC  -- explicit tiebreaker:
                                                    -- without it, a tied
                                                    -- severity count picks
                                                    -- an arbitrary winner
        ) AS severity_rank
    FROM defects
    GROUP BY defect_type, severity
) AS ranked_defects
WHERE severity_rank = 1
ORDER BY total_occurrences DESC, defect_type ASC  -- same reasoning:
                                                    -- makes the LIMIT cutoff
                                                    -- deterministic when
                                                    -- totals tie
LIMIT 5;

-- Note: for at least one defect type in this dataset, all of its
-- severity levels were tied at the same count -- meaning there is no
-- single true "most common severity," only a tiebreak. Reporting a
-- single answer here without noting the tie would be technically
-- correct but substantively misleading.
