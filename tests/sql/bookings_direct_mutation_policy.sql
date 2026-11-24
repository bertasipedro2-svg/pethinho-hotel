-- Regression guard: booking writes must use validated RPCs, not direct client policies.
BEGIN;
DO $$
BEGIN
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.bookings'::regclass) THEN
    RAISE EXCEPTION 'Bookings RLS disabled';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='bookings' AND cmd IN ('ALL','INSERT','UPDATE','DELETE') AND roles && ARRAY['public','anon','authenticated']::name[]) THEN
    RAISE EXCEPTION 'Direct booking mutation policy exposed';
  END IF;
END $$;
ROLLBACK;
