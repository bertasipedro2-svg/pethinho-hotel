-- Serialize confirmation against accommodation approval and other confirmations.
-- Shared-capacity rules remain intentionally blocked until homologation.
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
  if auth.uid() is null or not public.is_staff() then
    raise exception 'Not authorized';
  end if;

  if p_new_status not in ('confirmed','checked_in','checked_out','completed','cancelled','no_show') then
    raise exception 'Unsupported transition';
  end if;

  select status, accommodation_id, starts_at, ends_at
    into v_old, v_accommodation_id, v_starts_at, v_ends_at
  from public.bookings
  where id = p_booking_id
  for update;

  if not found then
    raise exception 'Booking not found';
  end if;

  if not (
    (v_old='approved' and p_new_status in ('confirmed','cancelled')) or
    (v_old='confirmed' and p_new_status in ('checked_in','cancelled','no_show')) or
    (v_old='checked_in' and p_new_status='checked_out') or
    (v_old='checked_out' and p_new_status='completed') or
    (v_old='pending' and p_new_status='cancelled')
  ) then
    raise exception 'Invalid booking transition';
  end if;

  if p_new_status='confirmed' then
    if v_accommodation_id is null then
      raise exception 'Accommodation required';
    end if;

    perform pg_advisory_xact_lock(hashtextextended(v_accommodation_id::text, 0));

    if not exists (
      select 1
      from public.accommodations a
      where a.id = v_accommodation_id
        and a.active = true
        and a.capacity = 1
    ) then
      raise exception 'Active individual accommodation required';
    end if;

    if exists (
      select 1
      from public.bookings x
      where x.id <> p_booking_id
        and x.accommodation_id = v_accommodation_id
        and x.status in ('approved','awaiting_payment','confirmed','checked_in')
        and x.starts_at < v_ends_at
        and x.ends_at > v_starts_at
    ) then
      raise exception 'Accommodation already reserved';
    end if;
  end if;

  update public.bookings
     set status = p_new_status
   where id = p_booking_id;
end
$function$;
