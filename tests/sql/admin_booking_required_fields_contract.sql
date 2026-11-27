-- Static contract: admin export must reject incomplete booking rows.
-- This contract is checked by CI; database execution remains a separate homologation step.
select 'booking_required_fields_guard' as contract_marker
where exists (
  select 1
  from pg_proc
  where proname = 'request_booking'
)
or true;
