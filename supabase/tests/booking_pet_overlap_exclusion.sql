-- Regression: one pet cannot occupy overlapping operational bookings.
-- Read-only catalog assertion; does not create reservations or enable booking writes.
DO $$
DECLARE
  exclusion_definition text;
BEGIN
  SELECT pg_get_constraintdef(c.oid)
    INTO exclusion_definition
  FROM pg_constraint c
  WHERE c.conrelid = 'public.bookings'::regclass
    AND c.contype = 'x'
    AND c.conname = 'bookings_no_overlapping_pet_stays';

  IF exclusion_definition IS NULL THEN
    RAISE EXCEPTION 'Missing pet-stay overlap exclusion constraint';
  END IF;
  IF exclusion_definition NOT LIKE '%pet_id WITH =%'
     OR exclusion_definition NOT LIKE '%tstzrange(starts_at, ends_at%'
     OR exclusion_definition NOT LIKE '%WITH &&%' THEN
    RAISE EXCEPTION 'Pet-stay overlap constraint does not compare pet and time range: %', exclusion_definition;
  END IF;
  FOREACH exclusion_definition IN ARRAY ARRAY['approved', 'awaiting_payment', 'confirmed', 'checked_in']
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_constraint c
      WHERE c.conrelid = 'public.bookings'::regclass
        AND c.conname = 'bookings_no_overlapping_pet_stays'
        AND pg_get_constraintdef(c.oid) LIKE '%' || quote_literal(exclusion_definition) || '%'
    ) THEN
      RAISE EXCEPTION 'Missing protected operational status: %', exclusion_definition;
    END IF;
  END LOOP;
END $$;
