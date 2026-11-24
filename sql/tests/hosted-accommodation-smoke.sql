-- Run only on development. All identities, rooms and bookings are temporary.
BEGIN;

DO $smoke$
DECLARE
  tutor_id uuid := gen_random_uuid();
  staff_id uuid := gen_random_uuid();
  admin_id uuid := gen_random_uuid();
  pet_id uuid;
  service_id uuid;
  room_id uuid;
  booking_id uuid;
  changed integer;
BEGIN
  INSERT INTO auth.users (id, email) VALUES
    (tutor_id, tutor_id || '@example.test'),
    (staff_id, staff_id || '@example.test'),
    (admin_id, admin_id || '@example.test');
  INSERT INTO public.staff_roles (user_id, role) VALUES (staff_id, 'staff'), (admin_id, 'admin');
  INSERT INTO public.pets (owner_id, name) VALUES (tutor_id, 'Pet de homologação') RETURNING id INTO pet_id;
  INSERT INTO public.services (name, active) VALUES ('Serviço de homologação', true) RETURNING id INTO service_id;
  INSERT INTO public.accommodations (name, capacity) VALUES ('Acomodação de homologação', 1) RETURNING id INTO room_id;

  SET LOCAL ROLE authenticated;
  PERFORM set_config('request.jwt.claim.sub', tutor_id::text, true);
  booking_id := public.request_booking(pet_id, service_id, now() + interval '1 day', now() + interval '2 days');
  UPDATE public.accommodations SET active = false WHERE id = room_id;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 0 THEN RAISE EXCEPTION 'Tutor could update room'; END IF;

  PERFORM set_config('request.jwt.claim.sub', staff_id::text, true);
  UPDATE public.accommodations SET active = false WHERE id = room_id;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 0 THEN RAISE EXCEPTION 'Staff could update room'; END IF;
  PERFORM public.approve_booking(booking_id, room_id);

  PERFORM set_config('request.jwt.claim.sub', admin_id::text, true);
  BEGIN
    UPDATE public.accommodations SET active = false WHERE id = room_id;
    RAISE EXCEPTION 'Blocked room could be deactivated';
  EXCEPTION WHEN check_violation THEN
    IF SQLERRM <> 'Accommodation has an upcoming reservation' THEN RAISE; END IF;
  END;

  PERFORM public.transition_booking(booking_id, 'cancelled');
  UPDATE public.accommodations SET active = false WHERE id = room_id;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 1 THEN RAISE EXCEPTION 'Admin could not deactivate free room'; END IF;
  UPDATE public.accommodations SET active = true WHERE id = room_id;
  GET DIAGNOSTICS changed = ROW_COUNT;
  IF changed <> 1 THEN RAISE EXCEPTION 'Admin could not reactivate room'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.bookings b WHERE b.id = booking_id AND b.accommodation_id = room_id AND b.status = 'cancelled') THEN
    RAISE EXCEPTION 'Booking history changed';
  END IF;
  RESET ROLE;
  -- Force the subtransaction to roll back even in clients that ignore the final ROLLBACK.
  RAISE SQLSTATE 'PT001';
EXCEPTION WHEN SQLSTATE 'PT001' THEN
  NULL;
END;
$smoke$;

SELECT 'PASS: hosted SQL accommodation smoke; fictional data rolled back' AS result;

ROLLBACK;
