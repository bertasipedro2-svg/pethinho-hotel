select
  has_function_privilege('anon', 'public.is_admin()', 'EXECUTE') = false
    and has_function_privilege('authenticated', 'public.is_admin()', 'EXECUTE') = false
    and has_function_privilege('anon', 'public.is_staff()', 'EXECUTE') = false
    and has_function_privilege('authenticated', 'public.is_staff()', 'EXECUTE') = false
  as role_helper_direct_execute_blocked;
