-- Simulate an authenticated identity that is not a staff member.
-- No fixtures, booking mutations or persistent session changes.
BEGIN;
SET LOCAL ROLE authenticated;
DO $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000000', true);
  PERFORM set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000000","role":"authenticated"}', true);
  IF public.is_staff() IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'Synthetic identity must not be staff';
  END IF;
  BEGIN
    PERFORM public.approve_booking(NULL::uuid, NULL::uuid);
    RAISE EXCEPTION 'Unauthorized approval unexpectedly succeeded';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'Not authorized' THEN RAISE; END IF;
  END;
END $$;
ROLLBACK;
