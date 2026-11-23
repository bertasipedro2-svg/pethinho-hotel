-- Behavioral regression: composite ownership FK, using isolated temporary fixtures.
-- No real bookings or accounts are created.
BEGIN;
CREATE TEMP TABLE test_pet_owner (id uuid NOT NULL, owner_id uuid NOT NULL, UNIQUE(id,owner_id)) ON COMMIT DROP;
CREATE TEMP TABLE test_booking_owner (pet_id uuid NOT NULL, owner_id uuid NOT NULL) ON COMMIT DROP;
DO $$
DECLARE definition text; p uuid := gen_random_uuid(); a uuid := gen_random_uuid(); b uuid := gen_random_uuid();
BEGIN
 SELECT pg_get_constraintdef(oid) INTO definition FROM pg_constraint WHERE conrelid='public.bookings'::regclass AND conname='bookings_pet_owner_fk' AND convalidated;
 IF definition IS DISTINCT FROM 'FOREIGN KEY (pet_id, owner_id) REFERENCES pets(id, owner_id)' THEN RAISE EXCEPTION 'Missing or unexpected ownership constraint'; END IF;
 EXECUTE 'ALTER TABLE test_booking_owner ADD CONSTRAINT test_owner_fk ' || replace(definition,'REFERENCES pets(', 'REFERENCES test_pet_owner(');
 INSERT INTO test_pet_owner VALUES(p,a);
 INSERT INTO test_booking_owner VALUES(p,a);
 BEGIN
   INSERT INTO test_booking_owner VALUES(p,b);
   RAISE EXCEPTION 'Mismatched owner accepted';
 EXCEPTION WHEN foreign_key_violation THEN NULL;
 END;
END $$;
ROLLBACK;
