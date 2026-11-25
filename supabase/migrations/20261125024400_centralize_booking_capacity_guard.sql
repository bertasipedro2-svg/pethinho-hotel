-- Centralize accommodation availability rules for approval and confirmation.
create or replace function public.assert_booking_capacity_available(
  p_accommodation_id uuid,
  p_booking_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_capacity integer;
  v_occupied integer;
begin
  select capacity into v_capacity
  from public.accommodations
  where id = p_accommodation_id and active = true
  for update;

  if not found then
    raise exception 'Accommodation unavailable';
  end if;

  -- Shared-capacity operation remains intentionally disabled until homologation.
  if v_capacity <> 1 then
    raise exception 'Shared accommodation capacity rules not configured';
  end if;

  select count(*) into v_occupied
  from public.bookings x
  where x.id <> p_booking_id
    and x.accommodation_id = p_accommodation_id
    and x.status in ('approved','awaiting_payment','confirmed','checked_in')
    and x.starts_at < p_ends_at
    and x.ends_at > p_starts_at;

  if v_occupied >= v_capacity then
    raise exception 'Accommodation already reserved';
  end if;
end
$function$;

create or replace function public.approve_booking(p_booking_id uuid, p_accommodation_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare b record;
begin
  if not public.is_staff() then raise exception 'Not authorized'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_accommodation_id::text,0));
  select * into b from public.bookings where id=p_booking_id for update;
  if not found or b.status<>'pending' then raise exception 'Booking is not pending'; end if;
  perform public.assert_booking_capacity_available(p_accommodation_id, b.id, b.starts_at, b.ends_at);
  update public.bookings set accommodation_id=p_accommodation_id,status='approved' where id=b.id;
end
$function$;

create or replace function public.transition_booking(p_booking_id uuid, p_new_status text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_old text;
  v_accommodation_id uuid;
  v_starts_at timestamptz;
  v_ends_at timestamptz;
begin
  if auth.uid() is null or not public.is_staff() then raise exception 'Not authorized'; end if;
  if p_new_status not in ('confirmed','checked_in','checked_out','completed','cancelled','no_show') then raise exception 'Unsupported transition'; end if;
  select status, accommodation_id, starts_at, ends_at into v_old, v_accommodation_id, v_starts_at, v_ends_at
  from public.bookings where id = p_booking_id for update;
  if not found then raise exception 'Booking not found'; end if;
  if not (
    (v_old='approved' and p_new_status in ('confirmed','cancelled')) or
    (v_old='confirmed' and p_new_status in ('checked_in','cancelled','no_show')) or
    (v_old='checked_in' and p_new_status='checked_out') or
    (v_old='checked_out' and p_new_status='completed') or
    (v_old='pending' and p_new_status='cancelled')
  ) then raise exception 'Invalid booking transition'; end if;
  if p_new_status='confirmed' then
    if v_accommodation_id is null then raise exception 'Accommodation required'; end if;
    perform pg_advisory_xact_lock(hashtextextended(v_accommodation_id::text, 0));
    perform public.assert_booking_capacity_available(v_accommodation_id, p_booking_id, v_starts_at, v_ends_at);
  end if;
  update public.bookings set status = p_new_status where id = p_booking_id;
end
$function$;