BEGIN;
DO $$
DECLARE k bigint := hashtextextended(gen_random_uuid()::text,0);
BEGIN
 PERFORM pg_advisory_xact_lock(k);
 IF NOT EXISTS (SELECT 1 FROM pg_locks WHERE pid=pg_backend_pid() AND locktype='advisory' AND granted AND mode='ExclusiveLock' AND classid::bigint=((k >> 32) & 4294967295) AND objid::bigint=(k & 4294967295) AND objsubid=1) THEN
 RAISE EXCEPTION 'Exact accommodation lock key not held';
 END IF;
END $$;
ROLLBACK;
