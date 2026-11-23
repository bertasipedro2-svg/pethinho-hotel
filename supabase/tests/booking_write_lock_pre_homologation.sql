-- PETHINHO HOTEL: fail closed until capacity and authorization are homologated.
-- Execute in pethinho-hotel-dev via Supabase SQL editor.
-- This is a configuration regression test, not a two-user RLS simulation.
DO $$
DECLARE write_policies integer;
BEGIN
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.bookings'::regclass) THEN
    RAISE EXCEPTION 'FAIL: bookings RLS disabled';
  END IF;

  SELECT count(*) INTO write_policies
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'bookings'
    AND cmd IN ('INSERT', 'UPDATE', 'DELETE', 'ALL')
    AND ('authenticated' = ANY(roles) OR 'public' = ANY(roles));

  IF write_policies <> 0 THEN
    RAISE EXCEPTION 'FAIL: % booking write policies permit authenticated/public roles before homologation', write_policies;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'bookings'
      AND cmd = 'SELECT'
      AND 'authenticated' = ANY(roles)
  ) THEN
    RAISE EXCEPTION 'FAIL: authenticated booking read policy missing';
  END IF;

  RAISE NOTICE 'PASS: RLS enabled, read policy present, no public/authenticated booking write policy';
END $$;
