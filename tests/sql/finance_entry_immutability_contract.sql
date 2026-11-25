-- PETHINHO HOTEL: finance immutability regression contract
select
  to_regclass('public.finance_entries') is not null as finance_entries_exists,
  exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid = t.tgrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = 'finance_entries'
      and t.tgname = 'trg_guard_finance_entry_settlement'
      and not t.tgenabled = 'D'
  ) as settlement_trigger_enabled,
  has_function_privilege('anon', 'public.guard_finance_entry_update()', 'execute') = false as anon_execute_blocked,
  has_function_privilege('authenticated', 'public.guard_finance_entry_update()', 'execute') as authenticated_execute_allowed;
