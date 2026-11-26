-- PETHINHO HOTEL: booking interval schema and integrity contract
-- Read-only contract executed in Supabase DEV during validation.

with required_columns as (
  select 'bookings'::text as table_name, 'starts_at'::text as column_name, 'timestamp with time zone'::text as data_type
  union all select 'bookings', 'ends_at', 'timestamp with time zone'
  union all select 'bookings', 'status', 'text'
  union all select 'accommodations', 'capacity', 'integer'
  union all select 'accommodations', 'active', 'boolean'
),
actual as (
  select table_name, column_name, data_type
  from information_schema.columns
  where table_schema='public'
),
checks as (
  select
    not exists (
      select 1
      from required_columns r
      left join actual a using (table_name, column_name, data_type)
      where a.column_name is null
    ) as required_schema_present,
    not exists (
      select 1 from public.bookings
      where starts_at >= ends_at
    ) as invalid_booking_intervals,
    not exists (
      select 1 from public.accommodations
      where capacity < 0
    ) as negative_capacity
)
select
  required_schema_present,
  invalid_booking_intervals,
  negative_capacity,
  (required_schema_present and invalid_booking_intervals and negative_capacity) as contract_passed
from checks;
