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

CREATE OR REPLACE FUNCTION public.approve_booking(p_booking_id uuid, p_accommodation_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare b record; a record;
begin
 if not public.is_staff() then raise exception 'Not authorized'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_accommodation_id::text,0));
 select * into b from public.bookings where id=p_booking_id for update;
 if not found or b.status<>'pending' then raise exception 'Booking is not pending'; end if;
 select * into a from public.accommodations where id=p_accommodation_id and active=true;
 if not found then raise exception 'Accommodation unavailable'; end if;
 if a.capacity<>1 then raise exception 'Shared accommodation capacity rules not configured'; end if;
 if exists(select 1 from public.bookings x where x.id<>b.id and x.accommodation_id=p_accommodation_id and x.status in ('approved','awaiting_payment','confirmed','checked_in') and x.starts_at<b.ends_at and x.ends_at>b.starts_at) then raise exception 'Accommodation already reserved'; end if;
 update public.bookings set accommodation_id=p_accommodation_id,status='approved' where id=b.id;
end $function$;

CREATE OR REPLACE FUNCTION public.transition_booking(p_booking_id uuid, p_new_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_old text;
begin
 if auth.uid() is null or not public.is_staff() then raise exception 'Not authorized'; end if;
 if p_new_status not in ('confirmed','checked_in','checked_out','completed','cancelled','no_show') then raise exception 'Unsupported transition'; end if;
 select status into v_old from public.bookings where id=p_booking_id for update;
 if not found then raise exception 'Booking not found'; end if;
 if not (
   (v_old='approved' and p_new_status in ('confirmed','cancelled')) or
   (v_old='confirmed' and p_new_status in ('checked_in','cancelled','no_show')) or
   (v_old='checked_in' and p_new_status='checked_out') or
   (v_old='checked_out' and p_new_status='completed') or
   (v_old='pending' and p_new_status='cancelled')
 ) then raise exception 'Invalid booking transition'; end if;
 if p_new_status='confirmed' and not exists (
   select 1 from public.accommodations a join public.bookings b on b.accommodation_id=a.id
   where b.id=p_booking_id and a.active=true and a.capacity=1
 ) then raise exception 'Active individual accommodation required'; end if;
 update public.bookings set status=p_new_status where id=p_booking_id;
end $function$;

CREATE OR REPLACE FUNCTION public.is_staff()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$ select exists(select 1 from public.staff_roles where user_id=auth.uid()) $function$;

CREATE OR REPLACE FUNCTION public.is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$ select exists(select 1 from public.staff_roles where user_id=auth.uid() and role='admin') $function$;