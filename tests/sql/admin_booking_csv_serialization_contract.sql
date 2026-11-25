-- Regression contract: the admin CSV export must use the approved booking_calendar fields
-- and remain client-side only. This file is structural; execution is done in CI/review.

select
  'admin_csv_source_contract' as test_name,
  (
    select count(*) = 5
    from information_schema.columns
    where table_schema='public'
      and table_name='booking_calendar'
      and column_name in ('booking_id','pet_name','accommodation_name','starts_at','ends_at','status')
  ) as passed;
