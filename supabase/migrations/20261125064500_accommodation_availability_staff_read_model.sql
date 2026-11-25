-- Read-only current availability projection for the administrative panel.
-- security_invoker preserves the underlying RLS policies.
create or replace view public.accommodation_availability
with (security_invoker = true)
as
select
  a.id as accommodation_id,
  a.name as accommodation_name,
  a.capacity,
  count(b.id) filter (
    where b.status in ('approved','confirmed','checked_in')
      and b.starts_at < now()
      and b.ends_at > now()
  )::integer as occupied_now,
  greatest(
    a.capacity - count(b.id) filter (
      where b.status in ('approved','confirmed','checked_in')
        and b.starts_at < now()
        and b.ends_at > now()
    )::integer,
    0
  ) as available_now,
  a.active
from public.accommodations a
left join public.bookings b
  on b.accommodation_id = a.id
group by a.id, a.name, a.capacity, a.active;

revoke all on table public.accommodation_availability from anon, public;
grant select on table public.accommodation_availability to authenticated;
