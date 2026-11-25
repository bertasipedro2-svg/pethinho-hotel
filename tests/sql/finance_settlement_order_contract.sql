-- Regression contract: a finance entry cannot be settled before its due date.
-- This is intentionally structural and read-only; it does not create or mutate ledger rows.

select
  to_regclass('public.finance_entries') is not null as finance_entries_exists,
  exists (
    select 1
    from pg_constraint
    where conrelid = 'public.finance_entries'::regclass
      and conname = 'finance_entry_settled_on_not_before_due_chk'
      and pg_get_constraintdef(oid) =
        'CHECK (((settled_on IS NULL) OR (settled_on >= due_on)))'
  ) as settlement_order_constraint_present,
  count(*) filter (
    where settled_on is not null
      and settled_on < due_on
  ) = 0 as no_invalid_existing_rows
from public.finance_entries;
