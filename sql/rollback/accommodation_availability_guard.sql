BEGIN;
DROP TRIGGER accommodations_guard_deactivation ON public.accommodations;
DROP FUNCTION public.guard_accommodation_deactivation();
COMMIT;
