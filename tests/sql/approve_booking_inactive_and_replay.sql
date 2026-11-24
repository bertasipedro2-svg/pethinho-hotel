-- Transactional regression: inactive accommodation and duplicate approval.
BEGIN;
DO $$
DECLARE
 u uuid := gen_random_uuid();
 p uuid := gen_random_uuid();
 s uuid := gen_random_uuid();
 a uuid := gen_random_uuid();
 b uuid := gen_random_uuid();
BEGIN
 INSERT INTO auth.users(id,email) VALUES(u,u::text||'@example.invalid');
 INSERT INTO public.profiles(id,full_name) VALUES(u,'SQL regression') ON CONFLICT(id) DO NOTHING;
 INSERT INTO public.staff_roles(user_id,role) VALUES(u,'staff');
 INSERT INTO public.pets(id,owner_id,name) VALUES(p,u,'Fixture');
 INSERT INTO public.services(id,name,active) VALUES(s,'SQL regression '||s,false);
 INSERT INTO public.accommodations(id,name,capacity,active) VALUES(a,'SQL regression '||a,1,false);
 INSERT INTO public.bookings(id,owner_id,pet_id,service_id,starts_at,ends_at,status) VALUES(b,u,p,s,'2099-01-01T12:00:00Z','2099-01-02T12:00:00Z','pending');
 PERFORM set_config('request.jwt.claim.sub',u::text,true);
 PERFORM set_config('request.jwt.claims',json_build_object('sub',u,'role','authenticated')::text,true);
 BEGIN
  PERFORM public.approve_booking(b,a);
  RAISE EXCEPTION 'Inactive accommodation accepted';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM <> 'Accommodation unavailable' THEN RAISE; END IF;
 END;
 IF NOT EXISTS(SELECT 1 FROM public.bookings WHERE id=b AND status='pending' AND accommodation_id IS NULL) THEN RAISE EXCEPTION 'Rejected booking changed'; END IF;
 UPDATE public.accommodations SET active=true WHERE id=a;
 PERFORM public.approve_booking(b,a);
 IF NOT EXISTS(SELECT 1 FROM public.bookings WHERE id=b AND status='approved' AND accommodation_id=a) THEN RAISE EXCEPTION 'Approval failed'; END IF;
 BEGIN
  PERFORM public.approve_booking(b,a);
  RAISE EXCEPTION 'Duplicate approval accepted';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM <> 'Booking is not pending' THEN RAISE; END IF;
 END;
END $$;
ROLLBACK;
