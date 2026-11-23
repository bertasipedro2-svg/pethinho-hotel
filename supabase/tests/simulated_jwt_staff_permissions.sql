-- Simulated JWT identities; no real accounts or bookings are created.
begin;
set local role authenticated;
do $$
declare
  a uuid := '11111111-1111-4111-8111-111111111111';
  b uuid := '22222222-2222-4222-8222-222222222222';
begin
  perform set_config('request.jwt.claim.sub', a::text, true);
  perform set_config('request.jwt.claims', json_build_object('sub',a,'role','authenticated')::text,true);
  if auth.uid() is distinct from a then raise exception 'JWT identity A failed'; end if;
  if public.is_admin() is distinct from false or public.is_staff() is distinct from false then raise exception 'Identity A privilege check failed'; end if;
  perform set_config('request.jwt.claim.sub', b::text, true);
  perform set_config('request.jwt.claims', json_build_object('sub',b,'role','authenticated')::text,true);
  if auth.uid() is distinct from b then raise exception 'JWT identity B failed'; end if;
  if public.is_admin() is distinct from false or public.is_staff() is distinct from false then raise exception 'Identity B privilege check failed'; end if;
end $$;
rollback;
