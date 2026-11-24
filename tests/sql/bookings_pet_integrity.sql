-- Read-only regression checks; no booking fixtures or operational writes.
BEGIN;
DO $$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.bookings'::regclass AND conname='bookings_no_overlapping_pet_stays' AND contype='x' AND convalidated AND NOT condeferrable AND pg_get_constraintdef(oid) LIKE '%pet_id WITH =%' AND pg_get_constraintdef(oid) LIKE '%tstzrange(starts_at, ends_at, ''[)''::text) WITH &&%' AND pg_get_constraintdef(oid) LIKE '%approved%awaiting_payment%confirmed%checked_in%') THEN
  RAISE EXCEPTION 'Missing immediate pet overlap exclusion';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.bookings'::regclass AND conname='bookings_pet_owner_fk' AND contype='f' AND convalidated AND pg_get_constraintdef(oid) LIKE 'FOREIGN KEY (pet_id, owner_id) REFERENCES pets(id, owner_id)%') THEN
  RAISE EXCEPTION 'Missing pet ownership foreign key';
 END IF;
 IF tstzrange('2026-01-01 12:00+00','2026-01-02 12:00+00','[)') && tstzrange('2026-01-02 12:00+00','2026-01-03 12:00+00','[)') THEN
  RAISE EXCEPTION 'Adjacent stays incorrectly overlap';
 END IF;
 IF NOT (tstzrange('2026-01-01 12:00+00','2026-01-02 12:00+00','[)') && tstzrange('2026-01-02 11:59+00','2026-01-03 12:00+00','[)')) THEN
  RAISE EXCEPTION 'Overlapping stays not detected';
 END IF;
END $$;
ROLLBACK;
