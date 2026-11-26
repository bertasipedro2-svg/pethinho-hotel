-- PETHINHO HOTEL booking capacity enforcement contract
-- Read-only CI contract: the database must keep a trigger that validates
-- accommodation capacity on booking insert/update.

with trigger_state as (
  select
    exists (
      select 1
      from pg_trigger tg
      join pg_class t on t.oid = tg.tgrelid
      join pg_namespace n on n.oid = t.relnamespace
      where n.nspname = 'public'
        and t.relname = 'bookings'
        and not tg.tgisinternal
        and tg.tgname = 'bookings_enforce_accommodation_capacity'
    ) as capacity_trigger_present,
    exists (
      select 1
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public'
        and p.proname = 'enforce_accommodation_booking_capacity'
    ) as capacity_function_present
)
select
  capacity_trigger_present,
  capacity_function_present,
  (capacity_trigger_present and capacity_function_present) as contract_passed
from trigger_state;
