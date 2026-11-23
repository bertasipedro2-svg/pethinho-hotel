-- Regression: pet ownership must be enforced by RLS.
-- Read-only catalog assertions; run against pethinho-hotel-dev.
DO $$
DECLARE
  insert_check text;
  update_check text;
  update_using text;
  delete_using text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='pets' AND c.relrowsecurity) THEN RAISE EXCEPTION 'pets RLS is disabled'; END IF;
  SELECT with_check INTO insert_check FROM pg_policies WHERE schemaname='public' AND tablename='pets' AND policyname='pets_insert' AND cmd='INSERT' AND 'authenticated'=ANY(roles);
  SELECT with_check, qual INTO update_check, update_using FROM pg_policies WHERE schemaname='public' AND tablename='pets' AND policyname='pets_update' AND cmd='UPDATE' AND 'authenticated'=ANY(roles);
  SELECT qual INTO delete_using FROM pg_policies WHERE schemaname='public' AND tablename='pets' AND policyname='pets_delete' AND cmd='DELETE' AND 'authenticated'=ANY(roles);
  IF insert_check IS NULL OR position('owner_id = auth.uid()' in insert_check)=0 OR update_check IS NULL OR position('owner_id = auth.uid()' in update_check)=0 OR update_using IS NULL OR position('owner_id = auth.uid()' in update_using)=0 OR delete_using IS NULL OR position('owner_id = auth.uid()' in delete_using)=0 THEN RAISE EXCEPTION 'Pet ownership policy missing or changed'; END IF;
  IF position('bookings' in delete_using)=0 THEN RAISE EXCEPTION 'Pet deletion no longer checks existing bookings'; END IF;
END $$;
