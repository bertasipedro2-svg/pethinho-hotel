-- PETHINHO HOTEL admin CSV export contract
-- Read-only contract: export must be sourced from the staff-scoped booking_calendar read model.
select
  exists (
    select 1 from information_schema.views
    where table_schema='public' and table_name='booking_calendar'
  ) as view_exists,
  (
    select count(*)=6
    from information_schema.columns
    where table_schema='public'
      and table_name='booking_calendar'
      and column_name in ('booking_id','pet_name','accommodation_name','starts_at','ends_at','status')
  ) as required_columns_present,
  not exists (
    select 1 from information_schema.role_table_grants
    where table_schema='public' and table_name='bookings'
      and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')
  ) as direct_booking_writes_blocked;
