-- PETHINHO HOTEL: operational RPC security contract
-- Run with a privileged database role in the DEV project.
with rpc as (
  select p.oid, p.proname, pg_get_function_identity_arguments(p.oid) as args,
         p.prosecdef,
         coalesce(array_to_string(p.proconfig, ','), '') as config,
         has_function_privilege('public', p.oid, 'EXECUTE') as public_exec,
         has_function_privilege('anon', p.oid, 'EXECUTE') as anon_exec,
         has_function_privilege('authenticated', p.oid, 'EXECUTE') as auth_exec
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and (
      (p.proname = 'approve_booking' and pg_get_function_identity_arguments(p.oid) = 'p_booking_id uuid, p_accommodation_id uuid')
      or (p.proname = 'request_booking' and pg_get_function_identity_arguments(p.oid) = 'p_pet_id uuid, p_service_id uuid, p_starts_at timestamp with time zone, p_ends_at timestamp with time zone, p_notes text')
      or (p.proname = 'transition_booking' and pg_get_function_identity_arguments(p.oid) = 'p_booking_id uuid, p_new_status text')
    )
)
select
  count(*) = 3 as three_operational_rpcs_present,
  bool_and(prosecdef) as all_security_definer,
  bool_and(config like '%search_path=%') as all_search_path_hardened,
  bool_and(not public_exec) as public_execute_revoked,
  bool_and(not anon_exec) as anon_execute_revoked,
  bool_and(auth_exec) as authenticated_execute_preserved
from rpc;