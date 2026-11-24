BEGIN;

CREATE FUNCTION public.guard_accommodation_deactivation()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  -- Approval and operational transitions lock this same accommodation row.
  -- Use a fresh snapshot after acquiring the lock to see a concurrent approval.
  IF current_setting('transaction_isolation') NOT IN ('read committed', 'read uncommitted') THEN
    RAISE SQLSTATE '40001' USING MESSAGE = 'Accommodation deactivation requires read committed';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.bookings b
    WHERE b.accommodation_id = NEW.id AND b.status = 'checked_in'
  ) THEN
    RAISE check_violation USING MESSAGE = 'Accommodation has a stay in progress';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.bookings b
    WHERE b.accommodation_id = NEW.id
      AND b.status IN ('approved', 'awaiting_payment', 'confirmed')
      AND b.ends_at > clock_timestamp()
  ) THEN
    RAISE check_violation USING MESSAGE = 'Accommodation has an upcoming reservation';
  END IF;

  RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.guard_accommodation_deactivation() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER accommodations_guard_deactivation
AFTER UPDATE OF active ON public.accommodations
FOR EACH ROW WHEN (OLD.active IS DISTINCT FROM NEW.active AND NEW.active IS FALSE)
EXECUTE FUNCTION public.guard_accommodation_deactivation();

COMMIT;
