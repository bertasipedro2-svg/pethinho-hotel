-- Serialize overlapping reservations on the accommodation row to prevent capacity races.
create or replace function public.enforce_accommodation_booking_capacity()
returns trigger language plpgsql set search_path = public, pg_temp as $$
declare room_capacity integer; room_active boolean; occupied integer;
begin
  if new.status not in ('approved','awaiting_payment','confirmed','checked_in') then return new; end if;
  if new.accommodation_id is null then
    raise check_violation using message = 'Operational booking requires an accommodation';
  end if;
  select capacity, active into room_capacity, room_active
  from public.accommodations where id = new.accommodation_id for update;
  if not found or room_active is distinct from true then
    raise check_violation using message = 'Accommodation is missing or inactive';
  end if;
  select count(*) into occupied from public.bookings b
  where b.accommodation_id = new.accommodation_id
    and b.id is distinct from new.id
    and b.status in ('approved','awaiting_payment','confirmed','checked_in')
    and tstzrange(b.starts_at,b.ends_at,'[)') && tstzrange(new.starts_at,new.ends_at,'[)');
  if occupied >= room_capacity then
    raise check_violation using message = 'Accommodation capacity exceeded';
  end if;
  return new;
end; $$;
drop trigger if exists bookings_enforce_accommodation_capacity on public.bookings;
create trigger bookings_enforce_accommodation_capacity
before insert or update of accommodation_id, starts_at, ends_at, status
on public.bookings for each row
execute function public.enforce_accommodation_booking_capacity();
