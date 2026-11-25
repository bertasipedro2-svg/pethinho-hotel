-- Regression contract for the admin status filter.
-- The UI must keep all database-supported booking statuses visible as filter options.
select
  'bookings_status_contract' as test_name,
  count(*) > 0 as passed
from pg_constraint c
join pg_class t on t.oid = c.conrelid
where t.relname = 'bookings'
  and pg_get_constraintdef(c.oid) ilike '%awaiting_payment%'
  and pg_get_constraintdef(c.oid) ilike '%checked_in%'
  and pg_get_constraintdef(c.oid) ilike '%checked_out%';