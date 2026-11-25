-- PETHINHO HOTEL: admin panel calendar read model contract
-- Read-only structural regression test for Supabase DEV.

do $$
declare
  v_relkind "char";
  v_columns integer;
begin
  select c.relkind into v_relkind
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname='public' and c.relname='booking_calendar';

  if v_relkind <> 'v' then
    raise exception 'booking_calendar must remain a view';
  end if;

  select count(*) into v_columns
  from information_schema.columns
  where table_schema='public'
    and table_name='booking_calendar'
    and column_name in ('booking_id','pet_name','accommodation_name','starts_at','ends_at','status');

  if v_columns <> 6 then
    raise exception 'booking_calendar contract is incomplete';
  end if;

  if has_table_privilege('anon','public.booking_calendar','select') then
    raise exception 'anon must not read booking_calendar';
  end if;

  if not has_table_privilege('authenticated','public.booking_calendar','select') then
    raise exception 'authenticated must read booking_calendar';
  end if;
end $$;
