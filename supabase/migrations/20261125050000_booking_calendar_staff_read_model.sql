-- Read-only calendar projection for authenticated users.
-- security_invoker preserves bookings/pets/accommodations RLS policies.
create or replace view public.booking_calendar
with (security_invoker = true)
as
select
  b.id as booking_id,
  b.owner_id,
  b.pet_id,
  p.name as pet_name,
  b.accommodation_id,
  a.name as accommodation_name,
  b.starts_at,
  b.ends_at,
  b.status,
  b.notes
from public.bookings b
join public.pets p on p.id = b.pet_id
left join public.accommodations a on a.id = b.accommodation_id;

revoke all on table public.booking_calendar from anon, public;
grant select on table public.booking_calendar to authenticated;
