-- Prevent accommodations with blank or whitespace-only names.
ALTER TABLE public.accommodations
  ADD CONSTRAINT accommodations_name_not_blank
  CHECK (length(btrim(name)) > 0);
