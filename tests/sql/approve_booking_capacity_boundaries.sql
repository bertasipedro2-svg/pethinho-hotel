-- Sequential capacity regression, not a concurrency test. All fixtures rolled back.
BEGIN;
DO $$
DECLARE
 u uuid := gen_random_uuid();
 p uuid := gen_random_uuid();
 p2 uuid := gen_random_uuid();
 s uuid := gen_random_uuid();
 a uuid := gen_random_uuid();
 shared uuid := gen_random_uuid();
 b uuid := gen_random_uuid();
 c uuid := gen_random_uuid();
 d uuid := gen_random_uuid();
BEGIN
 INSERT INTO auth.users(id,email) VALUES(u,u::text||'@example.invalid');
 INSERT INTO public.profiles(id,full_name) VALUES(u,'SQL regression') ON CONFLICT(id) DO NOTHING;
 INSERT INTO public.staff_roles(user_id,role) VALUES(u,'staff');
 INSERT INTO public.pets(id,owner_id,name) VALUES(p,u,'Fixture A'),(p2,u,'Fixture B');
 INSERT INTO public.services(id,name,active) VALUES(s,'SQL regression '||s,false);
 INSERT INTO public.accommodations(id,name,capacity,active) VALUES(a,'SQL regression '||a,1,true),(shared,'SQL regression '||shared,2,true);
 INSERT INTO public.bookings(id,owner_id,pet_id,service_id,starts_at,ends_at,status) VALUES
 (b,u,p,s,'2099-01-01T12:00:00Z','2099-01-02T12:00:00Z','pending'),
 (c,u,p2,s,'2099-01-01T13:00:00Z','2099-01-02T13:00:00Z','pending'),
 (d,u,p,s,'2099-01-02T12:00:00Z','2099-01-03T12:00:00Z','pending');
 PERFORM set_config('request.jwt.claim.sub',u::text,true);
 PERFORM set_config('request.jwt.claims',json_build_object('sub',u,'role','authenticated')::text,true);
 PERFORM public.approve_booking(b,a);
 BEGIN
  PERFORM public.approve_booking(c,a);
  RAISE EXCEPTION 'Overlap accepted';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM <> 'Accommodation already reserved' THEN RAISE; END IF;
 END;
 BEGIN
  PERFORM public.approve_booking(c,shared);
  RAISE EXCEPTION 'Unvalidated shared capacity accepted';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM <> 'Shared accommodation capacity rules not configured' THEN RAISE; END IF;
 END;
 PERFORM public.approve_booking(d,a);
 IF (SELECT count(*) FROM public.bookings WHERE id IN (b,d) AND status='approved' AND accommodation_id=a) <> 2 THEN RAISE EXCEPTION 'Expected two approved bookings'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.bookings WHERE id=c AND status='pending' AND accommodation_id IS NULL) THEN RAISE EXCEPTION 'Rejected booking changed'; END IF;
END $$;
ROLLBACK;
