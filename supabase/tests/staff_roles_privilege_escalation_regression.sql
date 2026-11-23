-- Regression: only administrators may write staff roles.
-- Read-only catalog assertions for pethinho-hotel-dev.
DO $$
DECLARE p record;
BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='staff_roles' AND c.relrowsecurity) THEN RAISE EXCEPTION 'staff_roles RLS disabled'; END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='staff_roles' AND policyname='roles_admin' AND cmd='ALL' AND 'authenticated'=ANY(roles) AND position('is_admin()' in coalesce(qual,''))>0 AND position('is_admin()' in coalesce(with_check,''))>0) THEN RAISE EXCEPTION 'Admin-only staff role write policy missing'; END IF;
 FOR p IN SELECT * FROM pg_policies WHERE schemaname='public' AND tablename='staff_roles' AND cmd IN ('ALL','INSERT','UPDATE','DELETE') LOOP
  IF 'public'=ANY(p.roles) OR 'anon'=ANY(p.roles) OR NOT ('authenticated'=ANY(p.roles) AND position('is_admin()' in coalesce(p.qual,''))>0 AND position('is_admin()' in coalesce(p.with_check,''))>0) THEN RAISE EXCEPTION 'Unsafe staff_roles write policy: %',p.policyname; END IF;
 END LOOP;
END $$;
