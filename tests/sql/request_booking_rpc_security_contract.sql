-- Request-booking RPC security contract for the development database.
-- Read-only contract: validates that authenticated users may request only their own bookings,
-- while anonymous/public execution remains revoked and the function is hardened.
with func as (
  select
    p.oid,
    p.prosecdef as security_definer,
    pg_get_functiondef(p.oid) as definition,
    has_function_privilege('public', p.oid, 'EXECUTE') as public_execute,
    has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname='public'
    and p.proname='request_booking'
    and pg_get_function_identity_arguments(p.oid) =
      'p_pet_id uuid, p_service_id uuid, p_starts_at timestamp with time zone, p_ends_at timestamp with time zone, p_notes text'
)
select
  count(*) = 1 as request_booking_present,
  bool_and(security_definer) as request_booking_security_definer,
  bool_and(definition ilike '%set search_path to ''''%' or definition ilike '%set search_path = ''''%') as request_booking_search_path_hardened,
  bool_and(definition ilike '%auth.uid()%') as request_booking_auth_guarded,
  bool_and(definition ilike '%owner_id = v_owner%') as request_booking_owner_guarded,
  bool_and(public_execute = false) as public_execute_revoked,
  bool_and(anon_execute = false) as anon_execute_revoked,
  bool_and(authenticated_execute = true) as authenticated_execute_preserved
from func;