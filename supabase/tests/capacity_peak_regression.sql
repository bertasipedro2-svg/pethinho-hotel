-- Regression: peak occupancy differs from total intersecting stays.
do $$
declare total_overlaps integer; peak integer;
begin
  with stays(s,e) as (values (1,3),(3,5)),
  events(t) as (values (1),(3))
  select (select count(*) from stays where s<5 and e>1),
         (select max((select count(*) from stays where s<=t and e>t)) from events)
  into total_overlaps,peak;
  if total_overlaps <> 2 or peak <> 1 then
    raise exception 'Unexpected occupancy calculation';
  end if;
end $$;

-- Existing trigger counts all intersecting stays, not peak simultaneous occupancy.
-- Capacity 2 should allow a new stay spanning these two adjacent stays.
-- This fixture verifies the mathematical distinction, not the live trigger or concurrency.
-- Keep real bookings disabled until corrected and homologated.
