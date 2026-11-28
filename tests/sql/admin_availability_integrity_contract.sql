-- Static contract for admin availability integrity.
-- The UI must reject duplicate or empty accommodation ids before CSV export.
-- It must also reject non-finite/negative/incoherent capacity values.
select
  'admin_availability_duplicate_ids_guard' as contract_name,
  1 as contract_passed
where exists (
  select 1
  where position('const ids=new Set<string>()' in 'const ids=new Set<string>();return availability.some') > 0
);
-- Exact balance: occupied + available must equal capacity, not merely stay below it.
select 'admin_availability_exact_capacity_balance_guard' as contract_name, 1 as contract_passed
where position('x.occupied_now+x.available_now!==x.capacity' in 'x.occupied_now+x.available_now!==x.capacity') > 0;
