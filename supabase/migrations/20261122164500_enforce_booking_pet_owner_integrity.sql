-- Prevent a booking from associating an owner's account with someone else's pet.
-- Database-level integrity check; RLS remains responsible for authorization.
create or replace function public.enforce_booking_pet_owner()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.pets p
    where p.id = new.pet_id and p.owner_id = new.owner_id
  ) then
    raise exception 'Booking pet must belong to booking owner'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists bookings_pet_owner_guard on public.bookings;
create trigger bookings_pet_owner_guard
before insert or update of owner_id, pet_id on public.bookings
for each row execute function public.enforce_booking_pet_owner();
