DO $$ BEGIN
IF to_regprocedure('public.request_booking(uuid,uuid,timestamp with time zone,timestamp with time zone,text)') IS NULL OR to_regprocedure('public.approve_booking(uuid,uuid)') IS NULL OR to_regprocedure('public.transition_booking(uuid,text)') IS NULL THEN RAISE EXCEPTION 'RPC contract mismatch'; END IF;
IF has_function_privilege('anon','public.request_booking(uuid,uuid,timestamp with time zone,timestamp with time zone,text)','EXECUTE') OR has_function_privilege('anon','public.approve_booking(uuid,uuid)','EXECUTE') OR has_function_privilege('anon','public.transition_booking(uuid,text)','EXECUTE') THEN RAISE EXCEPTION 'Anonymous booking access'; END IF;
END $$;
