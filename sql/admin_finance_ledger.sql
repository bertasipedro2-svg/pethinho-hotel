CREATE TABLE public.finance_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind text NOT NULL CHECK (kind IN ('income','expense')),
  description text NOT NULL CHECK (length(btrim(description)) BETWEEN 1 AND 160),
  amount_cents integer NOT NULL CHECK (amount_cents BETWEEN 1 AND 100000000),
  due_on date NOT NULL,
  settled_on date,
  created_by uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.finance_entries ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.finance_entries FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.finance_entries TO authenticated;
GRANT INSERT (kind,description,amount_cents,due_on) ON public.finance_entries TO authenticated;
GRANT UPDATE (settled_on) ON public.finance_entries TO authenticated;
CREATE POLICY finance_admin_select ON public.finance_entries
  FOR SELECT TO authenticated USING ((SELECT public.is_admin()));
CREATE POLICY finance_admin_insert ON public.finance_entries
  FOR INSERT TO authenticated WITH CHECK ((SELECT public.is_admin()) AND created_by = (SELECT auth.uid()));
CREATE POLICY finance_admin_settle ON public.finance_entries
  FOR UPDATE TO authenticated USING ((SELECT public.is_admin()) AND settled_on IS NULL)
  WITH CHECK ((SELECT public.is_admin()) AND settled_on = (timezone('America/Sao_Paulo', now())::date));
