-- Structural regression for confirmation-time capacity protection.
select
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='transition_booking'
      and pg_get_functiondef(p.oid) like '%pg_advisory_xact_lock(hashtextextended(v_accommodation_id::text, 0))%'
  ) as has_confirmation_lock,
  exists (
    select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='transition_booking'
      and pg_get_functiondef(p.oid) like '%Accommodation already reserved%'
  ) as has_overlap_guard,
  not exists (select 1 from pg_extension where extname='dblink') as dblink_absent;
