-- Read-only regression checks for booking duration and operational accommodation.
BEGIN;
DO $$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.bookings'::regclass AND conname='bookings_check' AND contype='c' AND convalidated AND pg_get_constraintdef(oid)='CHECK ((ends_at > starts_at))') THEN
  RAISE EXCEPTION 'Booking duration constraint missing or changed';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.bookings'::regclass AND conname='bookings_operational_accommodation_required' AND contype='c' AND convalidated AND pg_get_constraintdef(oid) LIKE '%approved%awaiting_payment%confirmed%checked_in%checked_out%completed%accommodation_id IS NOT NULL%') THEN
  RAISE EXCEPTION 'Operational accommodation constraint missing or changed';
 END IF;
 IF (SELECT count(*) FROM pg_attribute WHERE attrelid='public.bookings'::regclass AND attname IN ('starts_at','ends_at','status') AND attnotnull AND NOT attisdropped) <> 3 THEN
  RAISE EXCEPTION 'Required booking fields permit null';
 END IF;
END $$;
ROLLBACK;
