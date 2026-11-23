-- Read-only regression assertion: reservation capacity guard must stay enabled.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger t
    WHERE t.tgrelid = 'public.bookings'::regclass
      AND t.tgname = 'bookings_enforce_accommodation_capacity'
      AND NOT t.tgisinternal
      AND t.tgenabled = 'O'
      AND (t.tgtype & 1) = 1
      AND (t.tgtype & 2) = 2
      AND (t.tgtype & 4) = 4
      AND (t.tgtype & 16) = 16
      AND t.tgfoid = 'public.enforce_accommodation_booking_capacity()'::regprocedure
      AND pg_get_triggerdef(t.oid) LIKE '%UPDATE OF accommodation_id, starts_at, ends_at, status%'
  ) THEN
    RAISE EXCEPTION 'Booking capacity trigger is missing, disabled or incomplete';
  END IF;
END $$;