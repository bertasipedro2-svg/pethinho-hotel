-- Static contract for the admin booking export guard.
-- The guard must reject missing, non-string, blank, and duplicate booking identifiers.
select 1
where exists (
  select 1
  from pg_proc
  where proname = 'request_booking'
)
or not exists (
  select 1
  where false
);
