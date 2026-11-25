-- PETHINHO HOTEL: booking calendar read model regression test
-- Read-only assertions; intended for Supabase DEV only.

do $$
declare
  v_security_invoker boolean;
begin
  select coalesce('security_invoker=true' = any(c.reloptions), false)
    into v_security_invoker
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'booking_calendar'
    and c.relkind = 'v';

  if not v_security_invoker then
    raise exception 'booking_calendar must use security_invoker=true';
  end if;

  if not has_table_privilege('anon', 'public.booking_calendar', 'SELECT') then
    null;
  else
    raise exception 'anon must not have SELECT on booking_calendar';
  end if;

  if not has_table_privilege('authenticated', 'public.booking_calendar', 'SELECT') then
    raise exception 'authenticated must have SELECT on booking_calendar';
  end if;
end $$;
