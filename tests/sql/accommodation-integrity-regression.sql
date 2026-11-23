-- Read-only regression for accommodation integrity (run on pethinho-hotel-dev).
-- Fails if capacity positivity, nonblank/unique names or RLS are removed.
DO $$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.accommodations'::regclass AND conname='accommodations_capacity_check' AND pg_get_constraintdef(oid) LIKE '%capacity > 0%') THEN RAISE EXCEPTION 'Missing positive capacity constraint'; END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.accommodations'::regclass AND conname='accommodations_name_not_blank' AND pg_get_constraintdef(oid) LIKE '%length(btrim(name)) > 0%') THEN RAISE EXCEPTION 'Missing nonblank name constraint'; END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.accommodations'::regclass AND conname='accommodations_name_key' AND contype='u') THEN RAISE EXCEPTION 'Missing unique name constraint'; END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_class WHERE oid='public.accommodations'::regclass AND relrowsecurity) THEN RAISE EXCEPTION 'RLS disabled'; END IF;
END $$;
