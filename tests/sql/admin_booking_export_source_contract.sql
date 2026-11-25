-- Regression test for the authorized booking export source.
-- Run in Supabase DEV with the SQL test runner.
select
  to_regclass('public.booking_calendar') is not null as booking_calendar_exists,
  exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='booking_calendar'
      and column_name in ('booking_id','pet_name','starts_at','ends_at','status')
    group by table_schema, table_name
    having count(*) = 5
  ) as required_export_columns_present;
