-- Pethinho Hotel: staff-only booking state transitions.
-- Apply to pethinho-hotel-dev; never run against production without review.
create or replace function public.transition_booking(p_booking_id uuid,p_new_status text)
returns void language plpgsql security definer set search_path='' as $$
declare v_old text;
begin
 if auth.uid() is null or not public.is_staff() then raise exception 'Not authorized'; end if;
 if p_new_status not in ('checked_in','checked_out','completed','cancelled','no_show') then raise exception 'Unsupported transition'; end if;
 select status into v_old from public.bookings where id=p_booking_id for update;
 if not found then raise exception 'Booking not found'; end if;
 if not (
 (v_old='confirmed' and p_new_status in ('checked_in','cancelled','no_show')) or
 (v_old='checked_in' and p_new_status='checked_out') or
 (v_old='checked_out' and p_new_status='completed') or
 (v_old='approved' and p_new_status='cancelled') or
 (v_old='pending' and p_new_status='cancelled')
 ) then raise exception 'Invalid booking transition'; end if;
 update public.bookings set status=p_new_status where id=p_booking_id;
end $$;
revoke all on function public.transition_booking(uuid,text) from public,anon;
grant execute on function public.transition_booking(uuid,text) to authenticated;
