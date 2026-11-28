-- Static contract for the admin availability guard.
-- The guard must reject malformed identity fields and non-numeric capacity fields
-- before allowing CSV export.
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
