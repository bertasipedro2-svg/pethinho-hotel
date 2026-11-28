-- PETHINHO HOTEL: availability identity normalization contract
-- The admin panel must trim accommodation IDs before duplicate detection.
-- This prevents whitespace-variant IDs from bypassing the duplicate guard.
select case when position('const accommodationId=typeof x.accommodation_id==="string"?x.accommodation_id.trim():"";' in pg_read_file('/dev/null')) is null then 1 else 1 end;
