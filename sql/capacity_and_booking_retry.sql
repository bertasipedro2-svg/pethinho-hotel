CREATE OR REPLACE FUNCTION public.enforce_accommodation_booking_capacity()
RETURNS trigger LANGUAGE plpgsql SET search_path = ''
AS $$
DECLARE
  room_capacity integer;
  room_active boolean;
  occupied bigint;
BEGIN
  IF NEW.status NOT IN ('approved','awaiting_payment','confirmed','checked_in') THEN
    RETURN NEW;
  END IF;
  IF NEW.accommodation_id IS NULL OR NEW.ends_at <= NEW.starts_at THEN
    RAISE check_violation USING MESSAGE = 'Operational booking requires an accommodation and valid dates';
  END IF;
  -- The second statement must see commits made while the room lock was pending.
  IF current_setting('transaction_isolation') NOT IN ('read committed','read uncommitted') THEN
    RAISE SQLSTATE '40001' USING MESSAGE = 'Booking capacity requires read committed';
  END IF;
  SELECT a.capacity, a.active INTO room_capacity, room_active
  FROM public.accommodations a WHERE a.id = NEW.accommodation_id FOR UPDATE;
  IF NOT FOUND OR room_active IS DISTINCT FROM true THEN
    RAISE check_violation USING MESSAGE = 'Accommodation is missing or inactive';
  END IF;

  WITH clipped_stays AS (
    SELECT greatest(b.starts_at, NEW.starts_at) AS starts_at,
           least(b.ends_at, NEW.ends_at) AS ends_at
    FROM public.bookings b
    WHERE b.accommodation_id = NEW.accommodation_id
      AND b.id IS DISTINCT FROM NEW.id
      AND b.status IN ('approved','awaiting_payment','confirmed','checked_in')
      AND b.starts_at < NEW.ends_at AND b.ends_at > NEW.starts_at
  ), events AS (
    SELECT starts_at AS at, 1 AS delta FROM clipped_stays
    UNION ALL SELECT ends_at, -1 FROM clipped_stays
  ), grouped AS (
    SELECT at, sum(delta) AS delta FROM events GROUP BY at
  ), running AS (
    SELECT sum(delta) OVER (ORDER BY at) AS occupancy FROM grouped
  )
  SELECT coalesce(max(occupancy), 0) INTO occupied FROM running;

  IF occupied >= room_capacity THEN
    RAISE check_violation USING MESSAGE = 'Accommodation capacity exceeded';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.request_booking(
  p_pet_id uuid, p_service_id uuid, p_starts_at timestamptz, p_ends_at timestamptz,
  p_notes text DEFAULT NULL
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
  v_owner uuid := auth.uid();
  v_id uuid;
  v_service_active boolean;
BEGIN
  IF v_owner IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  IF p_starts_at IS NULL OR p_ends_at IS NULL OR p_starts_at < now()
     OR p_ends_at <= p_starts_at THEN RAISE EXCEPTION 'Invalid dates'; END IF;
  IF current_setting('transaction_isolation') NOT IN ('read committed','read uncommitted') THEN
    RAISE SQLSTATE '40001' USING MESSAGE = 'Booking requests require read committed';
  END IF;

  PERFORM 1 FROM public.pets WHERE id = p_pet_id AND owner_id = v_owner FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Pet not owned'; END IF;

  SELECT b.id INTO v_id FROM public.bookings b
  WHERE b.owner_id = v_owner AND b.pet_id = p_pet_id AND b.service_id = p_service_id
    AND b.starts_at = p_starts_at AND b.ends_at = p_ends_at
    AND b.status IN ('pending','approved','awaiting_payment','confirmed','checked_in')
  ORDER BY b.created_at, b.id LIMIT 1;
  IF FOUND THEN RETURN v_id; END IF;

  SELECT active INTO v_service_active FROM public.services WHERE id = p_service_id;
  IF v_service_active IS DISTINCT FROM true THEN RAISE EXCEPTION 'Service unavailable'; END IF;

  INSERT INTO public.bookings(owner_id,pet_id,service_id,starts_at,ends_at,status,notes)
  VALUES(v_owner,p_pet_id,p_service_id,p_starts_at,p_ends_at,'pending',left(p_notes,2000))
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;
