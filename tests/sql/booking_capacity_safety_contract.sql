-- PETHINHO HOTEL: contract for booking capacity and interval safety.
-- Read-only assertions; intended for Supabase DEV validation and CI review.

select
  'bookings_valid_interval_chk' as contract,
  exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'bookings'
      and c.conname = 'bookings_valid_interval_chk'
  ) as present;

select
  'booking_capacity_guard' as contract,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in ('approve_booking', 'request_booking', 'transition_booking')
  ) as operational_rpc_present;

select
  'invalid_booking_intervals' as contract,
  count(*) = 0 as passes,
  count(*) as invalid_rows
from public.bookings
where starts_at >= ends_at;

select
  'negative_capacity' as contract,
  count(*) = 0 as passes,
  count(*) as invalid_rows
from public.accommodations
where capacity < 0;
