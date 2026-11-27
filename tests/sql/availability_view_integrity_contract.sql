-- PETHINHO HOTEL: availability view integrity contract.
-- Read-only assertions for Supabase DEV and CI review.

select
  'availability_view_present' as contract,
  exists (
    select 1
    from pg_views
    where schemaname = 'public'
      and viewname = 'accommodation_availability'
  ) as passes;

select
  'availability_duplicate_ids' as contract,
  count(*) = 0 as passes,
  count(*) as duplicate_groups
from (
  select accommodation_id
  from public.accommodation_availability
  group by accommodation_id
  having count(*) > 1
) duplicates;

select
  'availability_values_consistent' as contract,
  count(*) = 0 as passes,
  count(*) as invalid_rows
from public.accommodation_availability
where capacity <= 0
   or occupied_now < 0
   or available_now < 0
   or occupied_now + available_now > capacity
   or (not active and (occupied_now <> 0 or available_now <> 0));

select
  'availability_contract_passed' as contract,
  (
    exists (
      select 1 from pg_views
      where schemaname = 'public'
        and viewname = 'accommodation_availability'
    )
    and not exists (
      select 1 from (
        select accommodation_id
        from public.accommodation_availability
        group by accommodation_id
        having count(*) > 1
      ) duplicates
    )
    and not exists (
      select 1 from public.accommodation_availability
      where capacity <= 0
         or occupied_now < 0
         or available_now < 0
         or occupied_now + available_now > capacity
         or (not active and (occupied_now <> 0 or available_now <> 0))
    )
  ) as passes;
