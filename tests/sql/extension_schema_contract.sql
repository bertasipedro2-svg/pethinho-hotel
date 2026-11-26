-- Read-only contract for the extension placement hardening.
select
  extname,
  nspname as installed_schema,
  (nspname = 'extensions') as moved_out_of_public
from pg_extension e
join pg_namespace n on n.oid = e.extnamespace
where extname = 'btree_gist';
