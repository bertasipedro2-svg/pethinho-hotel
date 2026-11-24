-- Isolated staff lifecycle regression; all fixtures rolled back.
BEGIN;
DO $$
DECLARE
 u uuid := gen_random_uuid();
 p uuid := gen_random_uuid();
 s uuid := gen_random_uuid();
 a uuid := gen_random_uuid();
 b uuid := gen_random_uuid();
 expected text;
BEGIN
 INSERT INTO auth.users(id,email) VALUES(u,u::text||'@example.invalid');
 INSERT INTO public.profiles(id,full_name) VALUES(u,'SQL regression') ON CONFLICT(id) DO NOTHING;
 INSERT INTO public.staff_roles(user_id,role) VALUES(u,'staff');
 INSERT INTO public.pets(id,owner_id,name) VALUES(p,u,'SQL regression');
 INSERT INTO public.services(id,name,active) VALUES(s,'SQL regression '||s,false);
 INSERT INTO public.accommodations(id,name,capacity,active) VALUES(a,'SQL regression '||a,1,true);
 INSERT INTO public.bookings(id,owner_id,pet_id,service_id,accommodation_id,starts_at,ends_at,status)
 VALUES(b,u,p,s,a,'2099-01-01T12:00:00Z','2099-01-02T12:00:00Z','approved');
 PERFORM set_config('request.jwt.claim.sub',u::text,true);
 PERFORM set_config('request.jwt.claims',json_build_object('sub',u,'role','authenticated')::text,true);
 IF auth.uid() IS DISTINCT FROM u OR NOT public.is_staff() THEN RAISE EXCEPTION 'Invalid staff fixture'; END IF;
 BEGIN
   PERFORM public.transition_booking(b,'checked_out');
   RAISE EXCEPTION 'Invalid transition accepted';
 EXCEPTION WHEN raise_exception THEN
   IF SQLERRM <> 'Invalid booking transition' THEN RAISE; END IF;
 END;
 FOREACH expected IN ARRAY ARRAY['confirmed','checked_in','checked_out','completed'] LOOP
   PERFORM public.transition_booking(b,expected);
   IF (SELECT status FROM public.bookings WHERE id=b) IS DISTINCT FROM expected THEN
     RAISE EXCEPTION 'Expected status %',expected;
   END IF;
 END LOOP;
END $$;
ROLLBACK;
