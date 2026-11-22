-- Keep operational stays linked to a physical accommodation.
-- Pending and cancelled requests may remain unassigned.
alter table public.bookings
  add constraint bookings_operational_accommodation_required
  check (
    status not in ('approved', 'awaiting_payment', 'confirmed', 'checked_in', 'checked_out', 'completed')
    or accommodation_id is not null
  );
