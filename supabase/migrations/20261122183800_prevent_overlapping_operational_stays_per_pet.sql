-- Prevent the same pet being assigned to overlapping operational bookings.
-- Pending, cancelled, no-show and finalized stays do not reserve a time slot.
-- '[)' allows adjacent bookings without overlap.
CREATE EXTENSION IF NOT EXISTS btree_gist;

ALTER TABLE public.bookings
  ADD CONSTRAINT bookings_no_overlapping_pet_stays
  EXCLUDE USING gist (
    pet_id WITH =,
    tstzrange(starts_at, ends_at, '[)') WITH &&
  )
  WHERE (status IN ('approved', 'awaiting_payment', 'confirmed', 'checked_in'));
