-- PETHINHO HOTEL: finance RLS contract
-- Read-only contract consumed by CI and manual verification.
-- Expected invariant: only admins can read/insert/settle finance entries.

select
  count(*) filter (
    where tablename = 'finance_entries'
      and policyname = 'finance_admin_select'
      and cmd = 'SELECT'
      and qual ilike '%is_admin%'
      and roles = '{authenticated}'
  ) = 1 as finance_select_admin_only,
  count(*) filter (
    where tablename = 'finance_entries'
      and policyname = 'finance_admin_insert'
      and cmd = 'INSERT'
      and with_check ilike '%is_admin%'
      and roles = '{authenticated}'
  ) = 1 as finance_insert_admin_only,
  count(*) filter (
    where tablename = 'finance_entries'
      and policyname = 'finance_admin_settle'
      and cmd = 'UPDATE'
      and qual ilike '%is_admin%'
      and with_check ilike '%is_admin%'
      and roles = '{authenticated}'
  ) = 1 as finance_settle_admin_only
from pg_policies
where schemaname = 'public'
  and tablename = 'finance_entries';

select
  count(*) = 0 as finance_non_admin_policy_present
from pg_policies
where schemaname = 'public'
  and tablename = 'finance_entries'
  and roles::text not like '%authenticated%'
  and roles::text not like '%service_role%';
