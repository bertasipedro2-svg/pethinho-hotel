-- Suspends access without losing existing financial history.
REVOKE SELECT ON public.finance_entries FROM authenticated;
REVOKE INSERT (kind,description,amount_cents,due_on) ON public.finance_entries FROM authenticated;
REVOKE UPDATE (settled_on) ON public.finance_entries FROM authenticated;
