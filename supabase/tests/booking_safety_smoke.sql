-- Read-only deployment smoke test for PETHINHO HOTEL booking safety.
-- Fails if a critical booking safeguard is missing or disabled.
DO $$
DECLARE missing text;
BEGIN
  SELECT string_agg(item, ', ') INTO missing FROM (
    SELECT 'bookings RLS' AS item WHERE NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.bookings'::regclass)
    UNION ALL SELECT 'pet overlap exclusion' WHERE NOT EXISTS (
      SELECT 1 FROM pg_constraint WHERE conrelid='public.bookings'::regclass
      AND conname='bookings_no_overlapping_pet_stays' AND contype='x' AND convalidated)
    UNION ALL SELECT 'operational accommodation constraint' WHERE NOT EXISTS (
      SELECT 1 FROM pg_constraint WHERE conrelid='public.bookings'::regclass
      AND conname='bookings_operational_accommodation_required' AND convalidated)
    UNION ALL SELECT 'capacity trigger' WHERE NOT EXISTS (
      SELECT 1 FROM pg_trigger WHERE tgrelid='public.bookings'::regclass
      AND tgname='bookings_enforce_accommodation_capacity' AND tgenabled IN ('O','A'))
    UNION ALL SELECT 'pet owner trigger' WHERE NOT EXISTS (
      SELECT 1 FROM pg_trigger WHERE tgrelid='public.bookings'::regclass
      AND tgname='bookings_pet_owner_guard' AND tgenabled IN ('O','A'))
  ) checks;
  IF missing IS NOT NULL THEN RAISE EXCEPTION 'Booking safety smoke test failed: %', missing; END IF;
  RAISE NOTICE 'Booking safety smoke test passed (schema checks only; no concurrent booking or RLS role simulation).';
END $$;