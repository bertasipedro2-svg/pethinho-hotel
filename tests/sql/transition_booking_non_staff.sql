-- Regression: authenticated non-staff cannot perform any operational transition.
BEGIN;
DO $$
DECLARE
  fake_user uuid := gen_random_uuid();
  target_status text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub',fake_user::text,true);
  PERFORM set_config('request.jwt.claims',json_build_object('sub',fake_user,'role','authenticated')::text,true);
  IF auth.uid() IS DISTINCT FROM fake_user OR public.is_staff() THEN
    RAISE EXCEPTION 'Invalid non-staff test identity';
  END IF;
  FOREACH target_status IN ARRAY ARRAY['confirmed','checked_in','checked_out','completed','cancelled','no_show'] LOOP
    BEGIN
      PERFORM public.transition_booking('00000000-0000-0000-0000-000000000000'::uuid,target_status);
      RAISE EXCEPTION 'Unauthorized transition unexpectedly succeeded: %',target_status;
    EXCEPTION WHEN raise_exception THEN
      IF SQLERRM <> 'Not authorized' THEN RAISE; END IF;
    END;
  END LOOP;
END $$;
ROLLBACK;
