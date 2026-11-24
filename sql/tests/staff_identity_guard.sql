-- Run without a JWT identity; neither helper may grant staff access.
DO $$ BEGIN IF auth.uid() IS NOT NULL THEN RAISE EXCEPTION 'Test requires no identity'; END IF; IF public.is_admin() OR public.is_staff() THEN RAISE EXCEPTION 'Unexpected staff privilege'; END IF; END $$;
