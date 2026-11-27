-- PETHINHO HOTEL booking lifecycle contract
-- Read-only verification contract for check-in/check-out safety.

with required_constraints as (
  select constraint_name
  from information_schema.table_constraints
  where table_schema='public'
    and table_name='bookings'
    and constraint_name in (
      'bookings_status_check',
      'bookings_operational_accommodation_required',
      'bookings_valid_interval_chk'
    )
),
status_contract as (
  select
    exists(select 1 from required_constraints where constraint_name='bookings_status_check') as status_constraint_present,
    exists(select 1 from required_constraints where constraint_name='bookings_operational_accommodation_required') as accommodation_required_constraint_present,
    exists(select 1 from required_constraints where constraint_name='bookings_valid_interval_chk') as interval_constraint_present,
    not exists (
      select 1
      from public.bookings
      where status in ('approved','awaiting_payment','confirmed','checked_in','checked_out','completed')
        and accommodation_id is null
    ) as operational_rows_have_accommodation,
    not exists (
      select 1
      from public.bookings
      where status not in ('pending','approved','awaiting_payment','confirmed','checked_in','checked_out','completed','cancelled','no_show')
    ) as statuses_are_valid
)
select *,
  (
    status_constraint_present
    and accommodation_required_constraint_present
    and interval_constraint_present
    and operational_rows_have_accommodation
    and statuses_are_valid
  ) as contract_passed
from status_contract;