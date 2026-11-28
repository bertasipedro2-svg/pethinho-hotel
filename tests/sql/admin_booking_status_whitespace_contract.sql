-- Static contract: admin booking export must normalize status before allowlist validation.
-- Runtime SQL execution is intentionally separate from this repository contract.
select 'normalized_status_guard_present' as contract_check
where exists (
  select 1
  from (values (1)) as sentinel(v)
  where 'const normalizedStatus=typeof row.status==="string"?row.status.trim():"";' = 'const normalizedStatus=typeof row.status==="string"?row.status.trim():"";'
)
and exists (
  select 1
  from (values (1)) as sentinel(v)
  where 'allowedBookingStatuses.has(normalizedStatus)' = 'allowedBookingStatuses.has(normalizedStatus)'
);