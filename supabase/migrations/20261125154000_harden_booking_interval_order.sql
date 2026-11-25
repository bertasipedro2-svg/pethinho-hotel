-- Prevent impossible booking intervals from entering the reservation lifecycle.
alter table public.bookings
  add constraint bookings_valid_interval_chk
  check (starts_at < ends_at);
