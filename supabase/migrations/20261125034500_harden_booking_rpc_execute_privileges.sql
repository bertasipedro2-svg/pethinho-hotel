-- Restrict booking RPC execution to authenticated callers.
revoke all on function public.approve_booking(uuid, uuid) from public, anon, authenticated;
revoke all on function public.transition_booking(uuid, text) from public, anon, authenticated;
revoke all on function public.assert_booking_capacity_available(uuid, uuid, timestamptz, timestamptz) from public, anon, authenticated;

grant execute on function public.approve_booking(uuid, uuid) to authenticated;
grant execute on function public.transition_booking(uuid, text) to authenticated;

comment on function public.assert_booking_capacity_available(uuid, uuid, timestamptz, timestamptz)
is 'Internal security-definer guard; not callable by API roles.';