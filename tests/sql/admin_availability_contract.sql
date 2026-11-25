-- Regression contract for the admin availability integration.
-- Intended to run in the Supabase SQL editor with the project test role.
select
  to_regclass('public.accommodation_availability') is not null as view_exists,
  exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='accommodation_availability'
      and column_name in ('accommodation_id','accommodation_name','capacity','occupied_now','available_now','active')
    group by table_schema, table_name
    having count(*) = 6
  ) as required_columns_present,
  exists (
    select 1
    from information_schema.views
    where table_schema='public'
      and table_name='accommodation_availability'
  ) as is_view;