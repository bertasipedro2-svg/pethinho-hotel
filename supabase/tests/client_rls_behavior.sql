-- Behavioral check on real public tables; all fixtures rolled back.
BEGIN;
INSERT INTO auth.users(id) VALUES ('a1000000-0000-4000-8000-000000000001'),('a1000000-0000-4000-8000-000000000002');
INSERT INTO public.profiles(id,full_name) VALUES ('a1000000-0000-4000-8000-000000000001','Fixture A'),('a1000000-0000-4000-8000-000000000002','Fixture B') ON CONFLICT(id) DO NOTHING;
INSERT INTO public.pets(id,owner_id,name) VALUES ('a2000000-0000-4000-8000-000000000001','a1000000-0000-4000-8000-000000000001','Fixture A'),('a2000000-0000-4000-8000-000000000002','a1000000-0000-4000-8000-000000000002','Fixture B');
SET LOCAL ROLE authenticated;
DO $$
DECLARE a uuid := 'a1000000-0000-4000-8000-000000000001'; b uuid := 'a1000000-0000-4000-8000-000000000002'; u uuid; n integer;
BEGIN
FOREACH u IN ARRAY ARRAY[a,b] LOOP
PERFORM set_config('request.jwt.claim.sub',u::text,true);
PERFORM set_config('request.jwt.claims',json_build_object('sub',u,'role','authenticated')::text,true);
IF (SELECT count(*) FROM public.pets WHERE owner_id IN (a,b)) <> 1 OR NOT EXISTS (SELECT 1 FROM public.pets WHERE owner_id=u) THEN RAISE EXCEPTION 'Pet visibility failure'; END IF;
IF (SELECT count(*) FROM public.profiles WHERE id IN (a,b)) <> 1 OR NOT EXISTS (SELECT 1 FROM public.profiles WHERE id=u) THEN RAISE EXCEPTION 'Profile visibility failure'; END IF;
UPDATE public.pets SET name='Forbidden' WHERE owner_id IN (a,b) AND owner_id<>u;
GET DIAGNOSTICS n=ROW_COUNT;
IF n<>0 THEN RAISE EXCEPTION 'Cross-owner update allowed'; END IF;
END LOOP;
END $$;
RESET ROLE;
ROLLBACK;
