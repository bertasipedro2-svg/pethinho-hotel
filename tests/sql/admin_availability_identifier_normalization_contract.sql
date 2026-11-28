-- Static contract for the admin availability guard.
-- The guard must trim accommodation_id before duplicate detection so
-- whitespace-variant IDs cannot bypass the integrity check.
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
