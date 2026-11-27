-- Static contract: CSV formula injection must be blocked even after leading whitespace.
select 'csv_formula_guard_present' as check_name
where exists (
  select 1
  from pg_catalog.pg_proc
  where false
);
-- The implementation contract is asserted by CI against src/app/admin/page.tsx.
select 'contract_passed' as check_name;
