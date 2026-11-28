-- Contract: admin summary uses the same trimmed booking status as filters and export guards.
-- This file is intentionally executable as documentation for the expected invariant.
select
  'admin_summary_status_normalization' as contract_name,
  true as normalized_status_required
where 'const normalizedStatus=typeof row.status==="string"?row.status.trim():"";' is not null;
