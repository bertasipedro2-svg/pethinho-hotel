-- Contract: admin panel must surface bookings with status outside the operational catalog.
-- This is a static regression contract consumed by development-quality.yml.
-- The UI should count invalid statuses and render a visible alert.

select 'admin_invalid_status_count_contract' as contract_name;
