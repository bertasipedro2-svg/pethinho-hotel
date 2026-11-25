-- Regression test: booking RPCs are not callable anonymously.
do $$
declare
  v_approve_acl text;
  v_transition_acl text;
  v_guard_acl text;
begin
  select coalesce(array_to_string(proacl, ','), '') into v_approve_acl
  from pg_proc where oid='public.approve_booking(uuid,uuid)'::regprocedure;
  select coalesce(array_to_string(proacl, ','), '') into v_transition_acl
  from pg_proc where oid='public.transition_booking(uuid,text)'::regprocedure;
  select coalesce(array_to_string(proacl, ','), '') into v_guard_acl
  from pg_proc where oid='public.assert_booking_capacity_available(uuid,uuid,timestamptz,timestamptz)'::regprocedure;

  if position('anon=X' in v_approve_acl) > 0 or position('public=X' in v_approve_acl) > 0 then
    raise exception 'approve_booking still executable by anon/public';
  end if;
  if position('anon=X' in v_transition_acl) > 0 or position('public=X' in v_transition_acl) > 0 then
    raise exception 'transition_booking still executable by anon/public';
  end if;
  if position('anon=X' in v_guard_acl) > 0 or position('public=X' in v_guard_acl) > 0 then
    raise exception 'capacity guard still executable by anon/public';
  end if;
end $$;