-- Adds covering indexes for foreign keys flagged by Supabase advisors.
create index if not exists bookings_accommodation_idx on public.bookings (accommodation_id);
create index if not exists bookings_pet_owner_idx on public.bookings (pet_id, owner_id);
create index if not exists bookings_service_idx on public.bookings (service_id);
create index if not exists finance_entries_created_by_idx on public.finance_entries (created_by);
create index if not exists pets_owner_idx on public.pets (owner_id);
