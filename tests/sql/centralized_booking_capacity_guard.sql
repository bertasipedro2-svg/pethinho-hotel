-- Structural regression test for the centralized capacity guard.
select
  to_regprocedure('public.assert_booking_capacity_available(uuid,uuid,timestamptz,timestamptz)') is not null as helper_exists,
  position('assert_booking_capacity_available' in pg_get_functiondef('public.approve_booking(uuid,uuid)')) > 0 as approve_delegates,
  position('assert_booking_capacity_available' in pg_get_functiondef('public.transition_booking(uuid,text)')) > 0 as transition_delegates,
  position('pg_advisory_xact_lock' in pg_get_functiondef('public.transition_booking(uuid,text)')) > 0 as confirmation_is_serialized,
  position('Shared accommodation capacity rules not configured' in pg_get_functiondef('public.assert_booking_capacity_available(uuid,uuid,timestamptz,timestamptz)')) > 0 as shared_capacity_still_blocked;