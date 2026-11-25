-- Structural regression test for the calendar read model.
select
  c.relname as relation_name,
  c.relkind,
  has_table_privilege('anon', 'public.booking_calendar', 'SELECT') as anon_can_select,
  has_table_privilege('authenticated', 'public.booking_calendar', 'SELECT') as authenticated_can_select
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname='public' and c.relname='booking_calendar';

select
  pg_get_viewdef('public.booking_calendar'::regclass, true) like '%security_invoker%' as uses_security_invoker;
