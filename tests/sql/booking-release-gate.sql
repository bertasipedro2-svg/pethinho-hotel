-- Release gate: customer booking writes must remain disabled until capacity homologation.
-- Read-only: fails if RLS or policy/grant protections regress.
DO $$
DECLARE rls_on boolean; policies integer; grants integer;
BEGIN
 SELECT relrowsecurity INTO rls_on FROM pg_class WHERE oid='public.bookings'::regclass;
 IF rls_on IS DISTINCT FROM true THEN RAISE EXCEPTION 'bookings RLS disabled'; END IF;
 SELECT count(*) INTO policies FROM pg_policies
 WHERE schemaname='public' AND tablename='bookings' AND permissive='PERMISSIVE'
 AND cmd IN ('ALL','INSERT','UPDATE','DELETE')
 AND roles && ARRAY['authenticated','anon','public']::name[];
 IF policies > 0 THEN RAISE EXCEPTION 'booking write policies found: %',policies; END IF;
 SELECT count(*) INTO grants FROM information_schema.role_table_grants
 WHERE table_schema='public' AND table_name='bookings' AND grantee IN ('anon','PUBLIC')
 AND privilege_type IN ('INSERT','UPDATE','DELETE');
 IF grants > 0 THEN RAISE EXCEPTION 'anonymous booking write grants found'; END IF;
 RAISE NOTICE 'PASS: bookings remain locked for customer writes';
END $$;
