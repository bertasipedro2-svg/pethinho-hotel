-- Validate pet registration data at the database boundary.
-- Optional weight remains NULL until measured; supplied weights must be positive.
ALTER TABLE public.pets
  ADD CONSTRAINT pets_name_not_blank CHECK (length(btrim(name)) > 0),
  ADD CONSTRAINT pets_weight_positive CHECK (weight_kg IS NULL OR weight_kg > 0);
