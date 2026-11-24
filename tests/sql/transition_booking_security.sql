-- Regression: operational status transitions must reject unauthenticated callers.
BEGIN;
DO $$
BEGIN
 IF has_function_privilege('anon','public.transition_booking(uuid,text)','EXECUTE') OR NOT has_function_privilege('authenticated','public.transition_booking(uuid,text)','EXECUTE') THEN
  RAISE EXCEPTION 'Unexpected transition privileges';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE oid='public.transition_booking(uuid,text)'::regprocedure AND prosecdef AND 'search_path=""'=ANY(proconfig)) THEN
  RAISE EXCEPTION 'Unsafe transition function configuration';
 END IF;
 PERFORM set_config('request.jwt.claim.sub','',true);
 PERFORM set_config('request.jwt.claims','{}',true);
 BEGIN
  PERFORM public.transition_booking('00000000-0000-0000-0000-000000000000'::uuid,'checked_in');
  RAISE EXCEPTION 'Unauthenticated transition unexpectedly succeeded';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM <> 'Not authorized' THEN RAISE; END IF;
 END;
END $$;
ROLLBACK;
