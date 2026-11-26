-- Contract for the admin availability safety guard.
-- This read-only contract is intended for CI/manual verification.
select
  exists (
    select 1
    from information_schema.views
    where table_schema='public'
      and table_name='accommodation_availability'
  ) as availability_view_exists,
  exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='accommodation_availability'
      and column_name in ('capacity','occupied_now','available_now')
    group by table_schema, table_name
    having count(*)=3
  ) as availability_columns_present;
