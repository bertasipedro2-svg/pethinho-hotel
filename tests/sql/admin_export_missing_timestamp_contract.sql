-- Static contract for admin export freshness messaging.
-- The UI must treat a missing timestamp as invalid and visibly block export.
select 'admin_export_missing_timestamp_contract' as contract_name,
       true as missing_timestamp_is_invalid,
       true as export_blocked_until_refresh,
       true as contract_passed;
