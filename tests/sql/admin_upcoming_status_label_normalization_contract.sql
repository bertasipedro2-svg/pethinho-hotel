-- Regression contract: upcoming booking labels must use normalized status.
-- The admin panel trims status before filtering and counting; the upcoming list
-- must render the same normalized value to avoid showing raw padded statuses.
select 'upcoming_booking_label_uses_normalized_status' as contract_name;
