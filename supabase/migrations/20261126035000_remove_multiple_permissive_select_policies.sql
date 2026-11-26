drop policy if exists services_admin on public.services;
drop policy if exists services_read on public.services;
create policy services_select on public.services
  for select to authenticated
  using (active or (select is_staff()) or (select is_admin()));
create policy services_insert on public.services
  for insert to authenticated
  with check ((select is_admin()));
create policy services_update on public.services
  for update to authenticated
  using ((select is_admin()))
  with check ((select is_admin()));
create policy services_delete on public.services
  for delete to authenticated
  using ((select is_admin()));

drop policy if exists roles_admin on public.staff_roles;
drop policy if exists roles_read on public.staff_roles;
create policy roles_select on public.staff_roles
  for select to authenticated
  using ((user_id = (select auth.uid())) or (select is_admin()));
create policy roles_insert on public.staff_roles
  for insert to authenticated
  with check ((select is_admin()));
create policy roles_update on public.staff_roles
  for update to authenticated
  using ((select is_admin()))
  with check ((select is_admin()));
create policy roles_delete on public.staff_roles
  for delete to authenticated
  using ((select is_admin()));