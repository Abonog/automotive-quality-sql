-- ============================================================
-- Supplier fail rate: which suppliers have the worst inspection
-- pass rate, and how much does it actually vary between them?
--
-- Run against: data/quality_practice_mysql.sql
-- ============================================================

SELECT
    parts.supplier_id,
    supp.supplier_name,
    COUNT(*) AS total_inspections,
    SUM(CASE WHEN insp.result = 'Fail' THEN 1 ELSE 0 END) AS fail_count,
    ROUND(
        100.0 * SUM(CASE WHEN insp.result = 'Fail' THEN 1 ELSE 0 END) / COUNT(*),
        1
    ) AS fail_rate_pct
FROM inspections AS insp
INNER JOIN production_batches AS pro_batches
    ON insp.batch_id = pro_batches.batch_id
INNER JOIN parts
    ON parts.part_id = pro_batches.part_id
INNER JOIN suppliers AS supp
    ON parts.supplier_id = supp.supplier_id
GROUP BY
    parts.supplier_id,
    supp.supplier_name
ORDER BY fail_rate_pct DESC;

-- Result on this dataset:
--   GammaPlastics    31.6%  (19 inspections, 6 fails)
--   DeltaElectric    15.8%
--   OmegaFasteners   14.8%
--   SigmaCoatings    11.5%
--   AlphaMetal        5.0%
--   BetaCast          4.8%
--
-- GammaPlastics fails at roughly 3x the rate of the best-performing
-- supplier (BetaCast) -- a large enough gap to be a real supplier
-- quality signal, not noise, and worth a supplier corrective-action
-- conversation in a real setting.
