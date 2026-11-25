-- Regression: the admin panel orders booking_calendar by booking_id,
-- which is the exposed stable identifier of the read model.
do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='booking_calendar'
      and column_name='booking_id'
  ) then
    raise exception 'booking_calendar.booking_id is missing';
  end if;
end $$;

select
  'booking_calendar_booking_id_contract' as test_name,
  true as passed;
