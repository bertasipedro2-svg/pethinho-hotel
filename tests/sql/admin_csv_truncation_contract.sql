-- Regression contract: incomplete admin result sets must not be exportable.
-- The UI may export only the rows loaded from the authorized read model.
select
  to_regclass('public.booking_calendar') is not null as booking_calendar_exists,
  exists (
    select 1
    from information_schema.columns
    where table_schema='public' and table_name='booking_calendar'
      and column_name in ('booking_id','pet_name','accommodation_name','starts_at','ends_at','status')
    group by table_schema, table_name
    having count(*) = 6
  ) as required_columns_present,
  not exists (
    select 1
    from information_schema.role_table_grants
    where table_schema='public'
      and table_name='bookings'
      and privilege_type in ('INSERT','UPDATE','DELETE')
      and grantee in ('anon','authenticated')
  ) as direct_booking_writes_blocked;
