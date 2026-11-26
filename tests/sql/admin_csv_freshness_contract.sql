-- PETHINHO HOTEL: admin CSV freshness contract
-- Read-only contract for CI/review. Export must be blocked when last refresh is older than 5 minutes.
select 'admin_csv_freshness_contract' as contract, 5 as max_age_minutes, true as export_must_require_recent_refresh;
