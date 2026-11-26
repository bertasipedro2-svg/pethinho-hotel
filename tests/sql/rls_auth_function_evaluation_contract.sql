-- Contract: RLS auth helpers should be wrapped in SELECT to avoid per-row re-evaluation.
select count(*) as unoptimized_policies
from pg_policies
where schemaname = 'public'
  and policyname in (
    'profiles_read','profiles_insert','profiles_update',
    'pets_read','pets_insert','pets_update','pets_delete',
    'bookings_read','accommodations_read',
    'accommodations_admin_insert','accommodations_admin_update','accommodations_admin_delete',
    'services_admin','services_read','roles_admin','roles_read'
  )
  and (
    coalesce(qual,'') ~ '(auth\\.uid\\(\\)|is_staff\\(\\)|is_admin\\(\\))'
    or coalesce(with_check,'') ~ '(auth\\.uid\\(\\)|is_staff\\(\\)|is_admin\\(\\))'
  )
;
