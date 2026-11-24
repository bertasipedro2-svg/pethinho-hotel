-- Smoke test only: does not establish concurrency across independent sessions.
BEGIN;
DO $$
DECLARE a uuid := gen_random_uuid(); b uuid := gen_random_uuid(); n integer;
BEGIN
 PERFORM pg_advisory_xact_lock(hashtextextended(a::text,0));
 SELECT count(*) INTO n FROM pg_locks WHERE pid=pg_backend_pid() AND locktype='advisory' AND granted AND mode='ExclusiveLock';
 IF n < 1 THEN RAISE EXCEPTION 'Expected exclusive advisory lock'; END IF;
 IF NOT pg_try_advisory_xact_lock(hashtextextended(b::text,0)) THEN RAISE EXCEPTION 'Independent fixture key unexpectedly locked'; END IF;
END $$;
ROLLBACK;
