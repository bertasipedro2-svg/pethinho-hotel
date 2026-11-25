-- Regression contract for booking interval validation.
select
  exists (
    select 1
    from pg_constraint
    where conrelid = 'public.bookings'::regclass
      and conname = 'bookings_valid_interval_chk'
      and pg_get_constraintdef(oid) = 'CHECK ((starts_at < ends_at))'
  ) as passed;
