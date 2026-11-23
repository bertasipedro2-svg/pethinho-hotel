-- PETHINHO HOTEL: deterministic half-open booking interval regression.
-- Execute against development Supabase SQL editor. Read-only; no fixtures required.
-- Adjacent checkout/check-in must not be considered an overlap.
DO $$
DECLARE failures integer;
BEGIN
  WITH scenarios(label, a_start, a_end, b_start, b_end, expected) AS (
    VALUES
      ('same interval', 0, 10, 0, 10, true),
      ('partial overlap', 0, 10, 5, 15, true),
      ('contained interval', 0, 20, 5, 10, true),
      ('touching checkout/checkin', 0, 10, 10, 20, false),
      ('separated intervals', 0, 10, 11, 20, false),
      ('reverse touching', 10, 20, 0, 10, false)
  )
  SELECT count(*) INTO failures
  FROM scenarios
  WHERE (a_start < b_end AND a_end > b_start) IS DISTINCT FROM expected;
  IF failures <> 0 THEN
    RAISE EXCEPTION 'Interval overlap regression: % failed scenarios', failures;
  END IF;
END $$;
-- NOTE: this verifies interval semantics, not actual concurrent booking enforcement.
