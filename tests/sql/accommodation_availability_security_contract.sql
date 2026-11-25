-- Structural regression checks for the availability read model.
select
  exists (
    select 1
    from pg_views
    where schemaname='public'
      and viewname='accommodation_availability'
  ) as view_exists,
  coalesce(
    (select option_value='true'
     from pg_options_to_table(
       (select reloptions from pg_class c
        join pg_namespace n on n.oid=c.relnamespace
        where n.nspname='public' and c.relname='accommodation_availability')
     ) where option_name='security_invoker'),
    false
  ) as security_invoker_enabled,
  has_table_privilege('anon','public.accommodation_availability','select') as anon_can_select,
  has_table_privilege('authenticated','public.accommodation_availability','select') as authenticated_can_select;