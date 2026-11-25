-- Regression contract for the admin availability integration.
select
  exists (
    select 1
    from information_schema.views
    where table_schema='public' and table_name='accommodation_availability'
  ) as view_exists,
  has_table_privilege('anon','public.accommodation_availability','SELECT') as anon_select,
  has_table_privilege('authenticated','public.accommodation_availability','SELECT') as authenticated_select,
  exists (
    select 1
    from information_schema.columns
    where table_schema='public'
      and table_name='accommodation_availability'
      and column_name in ('accommodation_id','accommodation_name','capacity','occupied_now','available_now','active')
    group by table_schema, table_name
    having count(*)=6
  ) as required_columns_present;
