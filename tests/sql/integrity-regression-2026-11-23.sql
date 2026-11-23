-- Read-only integrity regression for PETHINHO HOTEL.
-- Run against development database; raises an error if a violation exists.
DO $test$
DECLARE violations integer;
BEGIN
 SELECT count(*) INTO violations FROM public.bookings b
 WHERE b.ends_at <= b.starts_at;
 IF violations > 0 THEN RAISE EXCEPTION 'Invalid booking intervals: %', violations; END IF;

 SELECT count(*) INTO violations FROM public.accommodations a
 WHERE a.capacity IS NULL OR a.capacity <= 0;
 IF violations > 0 THEN RAISE EXCEPTION 'Invalid accommodation capacities: %', violations; END IF;

 SELECT count(*) INTO violations FROM public.bookings b
 JOIN public.pets p ON p.id = b.pet_id
 WHERE b.owner_id IS DISTINCT FROM p.owner_id;
 IF violations > 0 THEN RAISE EXCEPTION 'Booking owner mismatch: %', violations; END IF;
END $test$;
