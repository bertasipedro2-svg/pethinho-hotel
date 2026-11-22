-- PETHINHO HOTEL: read-only operational integrity regression.
-- Returns zero rows when no violations exist. Safe for CI and development.
WITH operational AS (
  SELECT b.*, a.capacity, a.active
  FROM public.bookings b
  LEFT JOIN public.accommodations a ON a.id = b.accommodation_id
  WHERE b.status IN ('approved','awaiting_payment','confirmed','checked_in')
), violations AS (
  SELECT 'operational_booking_without_active_accommodation' AS issue, id::text AS reference
  FROM operational WHERE accommodation_id IS NULL OR active IS DISTINCT FROM TRUE
  UNION ALL
  SELECT 'pet_owner_mismatch', b.id::text
  FROM public.bookings b JOIN public.pets p ON p.id = b.pet_id
  WHERE b.owner_id IS DISTINCT FROM p.owner_id
  UNION ALL
  SELECT 'overlapping_stay_same_pet', a.id::text
  FROM operational a JOIN operational b ON a.pet_id=b.pet_id AND a.id<b.id
   AND a.starts_at<b.ends_at AND b.starts_at<a.ends_at
  UNION ALL
  SELECT 'accommodation_over_capacity', id::text
  FROM operational o
  WHERE (SELECT count(*) FROM operational x
         WHERE x.accommodation_id=o.accommodation_id
         AND x.starts_at<o.ends_at AND x.ends_at>o.starts_at) > o.capacity
)
SELECT issue, reference FROM violations ORDER BY issue, reference;
