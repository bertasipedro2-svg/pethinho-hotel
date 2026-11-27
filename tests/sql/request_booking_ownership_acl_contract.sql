-- Request-booking ownership and ACL contract for the development database.
with fn as (
  select
    p.oid,
    pg_get_functiondef(p.oid) as definition,
    has_function_privilege('public', p.oid, 'EXECUTE') as public_execute,
    has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname='request_booking'
    and p.proargtypes::regtype[] = ARRAY['uuid'::regtype,'uuid'::regtype,'timestamp with time zone'::regtype,'timestamp with time zone'::regtype,'text'::regtype]
)
select
  count(*)=1 as request_booking_present,
  bool_and(definition ilike '%set search_path to ''''%' or definition ilike '%set search_path = ''''%') as search_path_hardened,
  bool_and(definition ilike '%Authentication required%') as auth_guard_present,
  bool_and(definition ilike '%Pet not owned%') as owner_guard_present,
  bool_and(public_execute=false) as public_execute_revoked,
  bool_and(anon_execute=false) as anon_execute_revoked,
  bool_and(authenticated_execute=true) as authenticated_execute_preserved,
  (
    count(*)=1
    and bool_and(definition ilike '%set search_path to ''''%' or definition ilike '%set search_path = ''''%')
    and bool_and(definition ilike '%Authentication required%')
    and bool_and(definition ilike '%Pet not owned%')
    and bool_and(public_execute=false)
    and bool_and(anon_execute=false)
    and bool_and(authenticated_execute=true)
  ) as contract_passed
from fn;