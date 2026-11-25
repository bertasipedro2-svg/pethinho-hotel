ALTER TABLE public.finance_entries
  ADD CONSTRAINT finance_entry_settled_on_not_before_due_chk
  CHECK (settled_on IS NULL OR settled_on >= due_on);
