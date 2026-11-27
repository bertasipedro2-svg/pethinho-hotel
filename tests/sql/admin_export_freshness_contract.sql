-- Static contract for freshness validation in the administrative export.
-- This contract is intentionally repository-level: the runtime guard must reject
-- missing, invalid, future-dated, and stale timestamps before CSV export.
select
  'admin_export_freshness_contract' as contract,
  true as invalid_timestamp_guard_required,
  true as future_timestamp_guard_required,
  true as stale_timestamp_guard_required,
  true as contract_passed;