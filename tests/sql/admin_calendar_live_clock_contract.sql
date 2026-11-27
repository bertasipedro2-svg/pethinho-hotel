-- Static contract for live calendar clock re-evaluation.
-- The window filter must depend on the live now state so 7/30-day views update after time advances.
select 'admin_calendar_live_clock' as contract_name,
       true as live_now_is_dependency,
       true as contract_passed;
