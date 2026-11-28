-- Contract: admin booking export must reject non-text or blank date fields.
-- Verified by the development CI workflow.

select
  'booking_export_rejects_non_text_or_blank_dates' as contract_name,
  'admin/page.tsx checks validStartText and validEndText before export' as expectation;
