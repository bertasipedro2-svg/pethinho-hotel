-- Restrict unauthenticated access to sensitive operational tables.
revoke all privileges on table
  public.profiles,
  public.pets,
  public.bookings,
  public.staff_roles,
  public.finance_entries
from anon;

-- Keep authenticated access policy-driven, but remove structural privileges
-- that are not required by the web client.
revoke references, trigger, truncate on table
  public.profiles,
  public.pets,
  public.bookings,
  public.staff_roles,
  public.finance_entries
from authenticated;
