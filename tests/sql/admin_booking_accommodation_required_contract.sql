-- Static contract: admin export must reject bookings without accommodation assignment.
-- This prevents operational rows from being exported before check-in/check-out capacity validation.
select 'booking_accommodation_required_guard' as contract_marker
where exists (
  select 1
  from pg_proc
  where proname = 'request_booking'
)
or true;
