-- Regression contract for admin status labels.
-- The admin panel must represent every booking status supported by the database,
-- including awaiting_payment, so counts are not silently omitted.

begin;

do $$
declare
  required_statuses text[] := array[
    'pending','approved','awaiting_payment','confirmed',
    'checked_in','checked_out','completed','cancelled','no_show'
  ];
  missing_count integer;
begin
  select count(*) into missing_count
  from unnest(required_statuses) s(status)
  where not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where c.contype = 'c'
      and n.nspname = 'public'
      and t.relname = 'bookings'
      and pg_get_constraintdef(c.oid) like '%' || s.status || '%'
  );

  if missing_count > 0 then
    raise exception 'booking status contract is missing % supported statuses', missing_count;
  end if;
end $$;

rollback;
