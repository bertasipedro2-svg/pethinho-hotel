-- Harden operational RPC execute privileges and search_path.
alter function public.approve_booking(uuid, uuid) set search_path = '';
alter function public.request_booking(uuid, uuid, timestamptz, timestamptz, text) set search_path = '';
alter function public.transition_booking(uuid, text) set search_path = '';

revoke execute on function public.approve_booking(uuid, uuid) from public, anon;
revoke execute on function public.request_booking(uuid, uuid, timestamptz, timestamptz, text) from public, anon;
revoke execute on function public.transition_booking(uuid, text) from public, anon;

grant execute on function public.approve_booking(uuid, uuid) to authenticated;
grant execute on function public.request_booking(uuid, uuid, timestamptz, timestamptz, text) to authenticated;
grant execute on function public.transition_booking(uuid, text) to authenticated;
