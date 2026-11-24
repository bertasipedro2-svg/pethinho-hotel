BEGIN;
CREATE TABLE public.hotel_applications (
  applicant_id uuid PRIMARY KEY DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  business_name text NOT NULL CHECK (length(btrim(business_name)) BETWEEN 2 AND 100),
  contact_name text NOT NULL CHECK (length(btrim(contact_name)) BETWEEN 2 AND 100),
  city text NOT NULL CHECK (length(btrim(city)) BETWEEN 2 AND 100),
  state text NOT NULL CHECK (state IN ('AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO')),
  activity text NOT NULL CHECK (activity IN ('hotel', 'daycare', 'both')),
  phone text NOT NULL CHECK (phone ~ '^[1-9][0-9]{9,10}$'),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX hotel_applications_review_queue ON public.hotel_applications (status, created_at, applicant_id);
ALTER TABLE public.hotel_applications ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.hotel_applications FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.hotel_applications TO authenticated;
GRANT INSERT (business_name, contact_name, city, state, activity, phone)
  ON public.hotel_applications TO authenticated;
GRANT UPDATE (status) ON public.hotel_applications TO authenticated;

CREATE POLICY hotel_applications_read ON public.hotel_applications FOR SELECT TO authenticated
  USING (applicant_id = (SELECT auth.uid()) OR (SELECT public.is_admin()));
CREATE POLICY hotel_applications_create ON public.hotel_applications FOR INSERT TO authenticated
  WITH CHECK (applicant_id = (SELECT auth.uid()) AND status = 'pending');
CREATE POLICY hotel_applications_review ON public.hotel_applications FOR UPDATE TO authenticated
  USING ((SELECT public.is_admin()) AND status = 'pending')
  WITH CHECK ((SELECT public.is_admin()) AND status IN ('accepted', 'declined'));
COMMIT;
