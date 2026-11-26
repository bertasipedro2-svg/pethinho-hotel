-- PETHINHO HOTEL: contrato de presença e integridade do módulo financeiro
with required_tables as (
  select to_regclass('public.finance_entries') as finance_entries,
         to_regclass('public.bookings') as bookings
),
checks as (
  select
    finance_entries is not null as finance_table_exists,
    bookings is not null as bookings_table_exists
  from required_tables
)
select *
from checks
where not (finance_table_exists and bookings_table_exists);

do $$
begin
  if to_regclass('public.finance_entries') is null then
    raise exception 'public.finance_entries must exist before enabling finance workflows';
  end if;
  if to_regclass('public.bookings') is null then
    raise exception 'public.bookings must exist before enabling booking workflows';
  end if;
end $$;
