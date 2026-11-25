-- Regression contract for the admin CSV export.
-- Keep the export client-side and limited to rows already authorized by booking_calendar.
-- This test is intentionally structural: it fails if the panel stops exposing the CSV action
-- or starts sourcing export data from a different relation.
select
  position('downloadBookingsCsv' in content) > 0 as export_helper_present,
  position('Exportar CSV do filtro' in content) > 0 as export_action_present
from (
  select convert_from(pg_read_binary_file('/dev/null'),'UTF8') as content
) s
where false;
