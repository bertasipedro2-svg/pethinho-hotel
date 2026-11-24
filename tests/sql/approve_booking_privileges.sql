-- Read-only regression check; no booking fixtures or mutations.
DO $$
BEGIN
  IF has_function_privilege('anon', 'public.approve_booking(uuid,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous role must not execute approve_booking';
  END IF;
  IF NOT has_function_privilege('authenticated', 'public.approve_booking(uuid,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'Authenticated staff RPC entry point unavailable';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE oid = 'public.approve_booking(uuid,uuid)'::regprocedure AND prosecdef AND proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'Approval RPC security configuration changed';
  END IF;
END $$;
-- Staff authorization and concurrent capacity require separate behavioral tests.
