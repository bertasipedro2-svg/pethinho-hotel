-- PETHINHO HOTEL — contrato de integridade financeira
-- Executar no Supabase DEV para validar o estado real.

select
  exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'finance_entries'
      and c.conname = 'finance_entries_settled_on_not_before_due_on'
  ) as settlement_date_constraint_present,
  (select count(*) = 0 from public.finance_entries where settled_on is not null and settled_on < due_on) as invalid_settlement_dates,
  (
    exists (
      select 1
      from pg_constraint c
      join pg_class t on t.oid = c.conrelid
      join pg_namespace n on n.oid = t.relnamespace
      where n.nspname = 'public'
        and t.relname = 'finance_entries'
        and c.conname = 'finance_entries_settled_on_not_before_due_on'
    )
    and (select count(*) = 0 from public.finance_entries where settled_on is not null and settled_on < due_on)
  ) as contract_passed;
