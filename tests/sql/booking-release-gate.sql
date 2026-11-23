-- Release gate: customer booking writes must remain disabled until capacity homologation.
-- Read-only: fails if RLS, permissive policies or client write grants regress.
-- Covers anon, authenticated and PUBLIC; service_role is intentionally excluded.
DO $$
DECLARE rls_on boolean; policy_count integer; grant_count integer;
BEGIN
 SELECT relrowsecurity INTO rls_on FROM pg_class WHERE oid='public.bookings'::regclass;
 IF rls_on IS DISTINCT FROM true THEN RAISE EXCEPTION 'bookings RLS disabled'; END IF;
 SELECT count(*) INTO policy_count FROM pg_policies
 WHERE schemaname='public' AND tablename='bookings' AND permissive='PERMISSIVE'
 AND cmd IN ('ALL','INSERT','UPDATE','DELETE')
 AND roles && ARRAY['authenticated','anon','public']::name[];
 IF policy_count > 0 THEN RAISE EXCEPTION 'booking write policies found: %',policy_count; END IF;
 SELECT count(*) INTO grant_count FROM information_schema.role_table_grants
 WHERE table_schema='public' AND table_name='bookings'
 AND lower(grantee) IN ('anon','authenticated','public')
 AND privilege_type IN ('INSERT','UPDATE','DELETE');
 IF grant_count > 0 THEN RAISE EXCEPTION 'client booking write grants found: %',grant_count; END IF;
 RAISE NOTICE 'PASS: bookings customer writes remain locked';
END $$;
