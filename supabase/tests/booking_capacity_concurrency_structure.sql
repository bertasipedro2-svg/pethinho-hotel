-- Read-only regression: accommodation capacity concurrency safeguards.
-- Run against development database; raises exception if a safeguard is absent.
-- This is structural verification, not a simultaneous-booking load test.
DO $$
DECLARE
  fn text;
  trg record;
BEGIN
  SELECT pg_get_functiondef(p.oid) INTO fn
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.proname='enforce_accommodation_booking_capacity'
    AND p.pronargs=0;

  IF fn IS NULL THEN
    RAISE EXCEPTION 'Capacity function missing';
  END IF;
  IF fn !~* 'for[[:space:]]+update' THEN
    RAISE EXCEPTION 'Capacity check missing accommodation row lock';
  END IF;
  IF fn NOT LIKE '%tstzrange%' OR fn NOT LIKE '%&&%' THEN
    RAISE EXCEPTION 'Capacity check missing time overlap comparison';
  END IF;
  IF fn NOT LIKE '%b.id is distinct from new.id%' THEN
    RAISE EXCEPTION 'Capacity check counts itself on updates';
  END IF;

  SELECT t.tgenabled, pg_get_triggerdef(t.oid) AS definition INTO trg
  FROM pg_trigger t
  WHERE t.tgrelid='public.bookings'::regclass
    AND t.tgname='bookings_enforce_accommodation_capacity';

  IF NOT FOUND OR trg.tgenabled NOT IN ('O','A') THEN
    RAISE EXCEPTION 'Capacity trigger missing or disabled';
  END IF;
  IF trg.definition NOT LIKE '%INSERT%'
     OR trg.definition NOT LIKE '%UPDATE%' THEN
    RAISE EXCEPTION 'Capacity trigger does not cover insert and update';
  END IF;
  RAISE NOTICE 'PASS: capacity trigger, row lock, overlap and self-exclusion';
END $$;
