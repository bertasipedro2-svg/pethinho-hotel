-- Optimize RLS policies by evaluating auth helpers once per statement.
-- Semantics are unchanged; this removes per-row auth.uid()/helper evaluation.

drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select to authenticated using ((id = (select auth.uid())) or (select is_staff()));

drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles for insert to authenticated with check (id = (select auth.uid()));

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy if exists pets_read on public.pets;
create policy pets_read on public.pets for select to authenticated using ((owner_id = (select auth.uid())) or (select is_staff()));

drop policy if exists pets_insert on public.pets;
create policy pets_insert on public.pets for insert to authenticated with check (owner_id = (select auth.uid()));

drop policy if exists pets_update on public.pets;
create policy pets_update on public.pets for update to authenticated using (owner_id = (select auth.uid())) with check (owner_id = (select auth.uid()));

drop policy if exists pets_delete on public.pets;
create policy pets_delete on public.pets for delete to authenticated using ((owner_id = (select auth.uid())) and not exists (select 1 from public.bookings b where b.pet_id = pets.id));

drop policy if exists bookings_read on public.bookings;
create policy bookings_read on public.bookings for select to authenticated using ((owner_id = (select auth.uid())) or (select is_staff()));

drop policy if exists accommodations_read on public.accommodations;
create policy accommodations_read on public.accommodations for select to authenticated using ((select is_staff()));

drop policy if exists accommodations_admin_insert on public.accommodations;
create policy accommodations_admin_insert on public.accommodations for insert to authenticated with check ((select is_admin()));

drop policy if exists accommodations_admin_update on public.accommodations;
create policy accommodations_admin_update on public.accommodations for update to authenticated using ((select is_admin())) with check ((select is_admin()));

drop policy if exists accommodations_admin_delete on public.accommodations;
create policy accommodations_admin_delete on public.accommodations for delete to authenticated using ((select is_admin()));

drop policy if exists services_admin on public.services;
create policy services_admin on public.services for all to authenticated using ((select is_admin())) with check ((select is_admin()));

drop policy if exists services_read on public.services;
create policy services_read on public.services for select to authenticated using (active or (select is_staff()));

drop policy if exists roles_admin on public.staff_roles;
create policy roles_admin on public.staff_roles for all to authenticated using ((select is_admin())) with check ((select is_admin()));

drop policy if exists roles_read on public.staff_roles;
create policy roles_read on public.staff_roles for select to authenticated using ((user_id = (select auth.uid())) or (select is_admin()));
