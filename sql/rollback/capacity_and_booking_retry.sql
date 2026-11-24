CREATE OR REPLACE FUNCTION public.enforce_accommodation_booking_capacity()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  room_capacity integer;
  room_active boolean;
  occupied integer;
begin
  if new.status not in ('approved','awaiting_payment','confirmed','checked_in') then
    return new;
  end if;
  if new.accommodation_id is null then
    raise check_violation using message = 'Operational booking requires an accommodation';
  end if;
  select capacity, active into room_capacity, room_active
  from public.accommodations
  where id = new.accommodation_id
  for update;
  if not found or room_active is distinct from true then
    raise check_violation using message = 'Accommodation is missing or inactive';
  end if;
  select count(*) into occupied
  from public.bookings b
  where b.accommodation_id = new.accommodation_id
    and b.id is distinct from new.id
    and b.status in ('approved','awaiting_payment','confirmed','checked_in')
    and tstzrange(b.starts_at,b.ends_at,'[)') && tstzrange(new.starts_at,new.ends_at,'[)');
  if occupied >= room_capacity then
    raise check_violation using message = 'Accommodation capacity exceeded';
  end if;
  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.request_booking(p_pet_id uuid, p_service_id uuid, p_starts_at timestamp with time zone, p_ends_at timestamp with time zone, p_notes text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_owner uuid:=auth.uid(); v_id uuid; v_service_active boolean;
begin
 if v_owner is null then raise exception 'Authentication required'; end if;
 if p_starts_at < now() or p_ends_at<=p_starts_at then raise exception 'Invalid dates'; end if;
 if not exists(select 1 from public.pets where id=p_pet_id and owner_id=v_owner) then raise exception 'Pet not owned'; end if;
 select active into v_service_active from public.services where id=p_service_id;
 if v_service_active is distinct from true then raise exception 'Service unavailable'; end if;
 insert into public.bookings(owner_id,pet_id,service_id,starts_at,ends_at,status,notes)
 values(v_owner,p_pet_id,p_service_id,p_starts_at,p_ends_at,'pending',left(p_notes,2000)) returning id into v_id;
 return v_id;
end $function$;