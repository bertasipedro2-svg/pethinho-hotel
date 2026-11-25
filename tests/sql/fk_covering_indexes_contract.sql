-- PETHINHO HOTEL: FK covering indexes contract
-- Read-only verification for the performance hardening migration.
select count(*) = 5 as all_fk_indexes_present
from pg_indexes
where schemaname = 'public'
  and indexname in (
    'bookings_accommodation_idx',
    'bookings_pet_owner_idx',
    'bookings_service_idx',
    'finance_entries_created_by_idx',
    'pets_owner_idx'
  );