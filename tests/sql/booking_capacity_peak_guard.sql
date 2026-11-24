-- Regression for the database capacity guard, independent of the approval RPC.
-- Synthetic fixtures; no persistent data. Not a concurrent-session test.
BEGIN;
DO $$
DECLARE
 u uuid := gen_random_uuid();
 p uuid := gen_random_uuid();
 p2 uuid := gen_random_uuid();
 p3 uuid := gen_random_uuid();
 s uuid := gen_random_uuid();
 a uuid := gen_random_uuid();
 b uuid := gen_random_uuid();
 c uuid := gen_random_uuid();
 d uuid := gen_random_uuid();
BEGIN
 INSERT INTO auth.users(id,email) VALUES(u,u::text||'@example.invalid');
 INSERT INTO public.profiles(id,full_name) VALUES(u,'SQL regression') ON CONFLICT(id) DO NOTHING;
 INSERT INTO public.pets(id,owner_id,name) VALUES(p,u,'Fixture A'),(p2,u,'Fixture B'),(p3,u,'Fixture C');
 INSERT INTO public.services(id,name,active) VALUES(s,'SQL regression '||s,false);
 INSERT INTO public.accommodations(id,name,capacity,active) VALUES(a,'SQL regression '||a,2,true);
 INSERT INTO public.bookings(id,owner_id,pet_id,service_id,accommodation_id,starts_at,ends_at,status) VALUES
 (b,u,p,s,a,'2099-01-01T12:00:00Z','2099-01-02T12:00:00Z','approved'),
 (c,u,p2,s,a,'2099-01-02T12:00:00Z','2099-01-03T12:00:00Z','approved'),
 (d,u,p3,s,a,'2099-01-01T13:00:00Z','2099-01-03T11:00:00Z','approved');
 -- Two consecutive stays must not be counted as simultaneous.
 BEGIN
 UPDATE public.bookings SET starts_at='2099-01-01T14:00:00Z' WHERE id=c;
 RAISE EXCEPTION 'Overcapacity update accepted';
 EXCEPTION WHEN check_violation THEN
 IF SQLERRM <> 'Accommodation capacity exceeded' THEN RAISE; END IF;
 END;
 IF NOT EXISTS (SELECT 1 FROM public.bookings WHERE id=c AND starts_at='2099-01-02T12:00:00Z') THEN
 RAISE EXCEPTION 'Rejected update changed booking';
 END IF;
END $$;
ROLLBACK;
