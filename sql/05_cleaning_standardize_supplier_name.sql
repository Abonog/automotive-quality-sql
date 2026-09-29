-- ============================================================
-- Cleaning step 2: standardize supplier_name.
--
-- The raw data has 45 distinct spellings of what should be just
-- 6 real suppliers (mixed case, stray leading/trailing whitespace:
-- 'AlphaMetal', 'ALPHAMETAL', '  alphametal', etc).
--
-- Run against: data/quality_raw_practice_mysql.sql
-- ============================================================

UPDATE raw_inspections
SET supplier_name = CASE LOWER(TRIM(supplier_name))
    WHEN 'alphametal'     THEN 'AlphaMetal'
    WHEN 'betacast'       THEN 'BetaCast'
    WHEN 'gammaplastics'  THEN 'GammaPlastics'
    WHEN 'deltaelectric'  THEN 'DeltaElectric'
    WHEN 'omegafasteners' THEN 'OmegaFasteners'
    WHEN 'sigmacoatings'  THEN 'SigmaCoatings'
    ELSE supplier_name   -- leaves placeholder-missing values ('N/A',
                          -- 'unknown', '-', '') untouched; those are
                          -- handled separately as a completeness
                          -- problem, not a spelling problem
END;

-- Why match on LOWER(TRIM(supplier_name)) rather than the raw column:
-- normalizing both sides of the comparison makes the match work
-- regardless of the database's collation (case-sensitive or not),
-- rather than silently depending on a default you didn't choose.
-- It also means this is a single, atomic statement -- there's no
-- half-transformed intermediate state if something goes wrong
-- partway through, unlike a two-step "capitalize first letter, then
-- fix known cases" approach (which also can't produce internal
-- capitals like "DeltaElectric" from a generic capitalization rule
-- anyway).
--
-- Result: 45 distinct spellings -> 6 correct supplier names
-- (+ the placeholder-missing values, addressed next).
