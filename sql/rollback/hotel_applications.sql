-- Desativa o acesso ao cadastro pelo aplicativo e preserva os pedidos existentes.
BEGIN;
REVOKE ALL ON public.hotel_applications FROM anon, authenticated, PUBLIC;
REVOKE INSERT (business_name, contact_name, city, state, activity, phone),
       UPDATE (status)
ON public.hotel_applications FROM authenticated;
COMMIT;
