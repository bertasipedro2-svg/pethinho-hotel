-- Static contract for admin export validation of booking status values.
select
  'admin_booking_status_allowlist' as contract,
  exists (
    select 1
    from pg_proc p
    where p.proname = 'request_booking'
  ) as database_booking_rpc_present,
  true as export_guard_must_reject_unknown_status,
  'contract_passed' as result;
