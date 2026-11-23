-- PETHINHO HOTEL: operational booking constraints regression (read-only).
-- Fails if required status, accommodation or date guards are removed.
DO $$
DECLARE
  status_def text;
  accommodation_def text;
  dates_def text;
  required_status text;
BEGIN
  SELECT pg_get_constraintdef(oid) INTO status_def FROM pg_constraint
    WHERE conrelid = 'public.bookings'::regclass AND conname = 'bookings_status_check' AND contype = 'c';
  IF status_def IS NULL THEN RAISE EXCEPTION 'Missing bookings_status_check'; END IF;
  FOREACH required_status IN ARRAY ARRAY['pending','approved','awaiting_payment','confirmed','checked_in','checked_out','completed','cancelled','no_show']
  LOOP
    IF position(quote_literal(required_status) IN status_def) = 0 THEN RAISE EXCEPTION 'Missing booking status %', required_status; END IF;
  END LOOP;
  SELECT pg_get_constraintdef(oid) INTO accommodation_def FROM pg_constraint
    WHERE conrelid = 'public.bookings'::regclass AND conname = 'bookings_operational_accommodation_required' AND contype = 'c';
  IF accommodation_def IS NULL OR position('accommodation_id IS NOT NULL' IN accommodation_def) = 0 THEN
    RAISE EXCEPTION 'Missing operational accommodation guard';
  END IF;
  FOREACH required_status IN ARRAY ARRAY['approved','awaiting_payment','confirmed','checked_in','checked_out','completed']
  LOOP
    IF position(quote_literal(required_status) IN accommodation_def) = 0 THEN
      RAISE EXCEPTION 'Operational status % lacks accommodation guard', required_status;
    END IF;
  END LOOP;
  SELECT pg_get_constraintdef(oid) INTO dates_def FROM pg_constraint
    WHERE conrelid = 'public.bookings'::regclass AND contype = 'c'
      AND pg_get_constraintdef(oid) LIKE '%ends_at > starts_at%';
  IF dates_def IS NULL THEN RAISE EXCEPTION 'Missing positive booking duration guard'; END IF;
END $$;
-- Checks schema guards, not transactional capacity or authorization.