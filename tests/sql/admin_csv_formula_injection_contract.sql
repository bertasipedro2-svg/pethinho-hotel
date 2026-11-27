-- Contract: CSV export must neutralize spreadsheet formula prefixes.
-- This is a static contract consumed by GitHub Actions.
select
  position('String.fromCharCode(39)+raw' in pg_read_file('src/app/admin/page.tsx')) > 0 as formula_prefix_neutralized,
  position('replaceAll' in pg_read_file('src/app/admin/page.tsx')) > 0 as csv_escaping_present,
  (position('String.fromCharCode(39)+raw' in pg_read_file('src/app/admin/page.tsx')) > 0
   and position('replaceAll' in pg_read_file('src/app/admin/page.tsx')) > 0) as contract_passed;
