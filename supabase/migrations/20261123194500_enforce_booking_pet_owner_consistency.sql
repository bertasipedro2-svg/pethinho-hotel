-- Ensure a booking cannot reference a pet belonging to a different owner.
-- Existing rows must satisfy this constraint before deployment.
ALTER TABLE public.pets ADD CONSTRAINT pets_id_owner_unique UNIQUE (id, owner_id);
ALTER TABLE public.bookings ADD CONSTRAINT bookings_pet_owner_fk
  FOREIGN KEY (pet_id, owner_id) REFERENCES public.pets(id, owner_id);
