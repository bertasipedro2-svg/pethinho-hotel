-- Contract: services and staff_roles must not have overlapping permissive SELECT policies.
select
  tablename,
  count(*) filter (where cmd = 'SELECT' and roles = '{authenticated}') as authenticated_select_policies
from pg_policies
where schemaname='public'
  and tablename in ('services','staff_roles')
group by tablename
having count(*) filter (where cmd = 'SELECT' and roles = '{authenticated}') <> 1;

-- Expected: zero rows.
