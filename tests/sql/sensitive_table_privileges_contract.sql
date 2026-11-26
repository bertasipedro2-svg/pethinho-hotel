-- Contract: unauthenticated clients must not have table privileges
select table_name, grantee, privilege_type
from information_schema.role_table_grants
where table_schema='public'
  and table_name in ('profiles','pets','bookings','staff_roles','finance_entries')
  and grantee='anon';

-- Expected: zero rows.

select table_name, grantee, privilege_type
from information_schema.role_table_grants
where table_schema='public'
  and table_name in ('profiles','pets','bookings','staff_roles','finance_entries')
  and grantee='authenticated'
  and privilege_type in ('REFERENCES','TRIGGER','TRUNCATE');

-- Expected: zero rows.
