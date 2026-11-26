-- Booking RPC security contract for the development database.
-- This file is executed by CI/SQL review tooling and is intentionally read-only.
with funcs as (
  select
    p.proname,
    pg_get_functiondef(p.oid) as definition,
    has_function_privilege('public', p.oid, 'EXECUTE') as public_execute,
    has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname='public'
    and p.proname in ('approve_booking','transition_booking')
)
select
  bool_and(definition ilike '%set search_path to ''''%' or definition ilike '%set search_path = ''''%' ) as all_booking_rpcs_hardened,
  bool_and(definition ilike '%is_staff()%') as all_booking_rpcs_staff_guarded,
  bool_and(public_execute = false) as public_execute_revoked,
  bool_and(anon_execute = false) as anon_execute_revoked,
  bool_and(authenticated_execute = true) as authenticated_execute_preserved
from funcs;