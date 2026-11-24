-- Candidate peak occupancy calculation; not deployed.
CREATE OR REPLACE FUNCTION public.enforce_accommodation_booking_capacity()
RETURNS trigger LANGUAGE plpgsql SET search_path TO '' AS $$
DECLARE room_capacity integer; room_active boolean; occupied integer;
BEGIN
 IF new.status NOT IN ('approved','awaiting_payment','confirmed','checked_in') THEN RETURN new; END IF;
 IF new.accommodation_id IS NULL THEN RAISE check_violation USING MESSAGE='Operational booking requires an accommodation'; END IF;
 SELECT capacity,active INTO room_capacity,room_active FROM public.accommodations WHERE id=new.accommodation_id FOR UPDATE;
 IF NOT FOUND OR room_active IS DISTINCT FROM true THEN RAISE check_violation USING MESSAGE='Accommodation is missing or inactive'; END IF;
 WITH overlapping AS (
 SELECT greatest(b.starts_at,new.starts_at) AS s, least(b.ends_at,new.ends_at) AS e FROM public.bookings b
 WHERE b.accommodation_id=new.accommodation_id AND b.id IS DISTINCT FROM new.id AND b.status IN ('approved','awaiting_payment','confirmed','checked_in') AND b.starts_at<new.ends_at AND b.ends_at>new.starts_at
 ), events AS (SELECT s AS t,1 AS delta FROM overlapping UNION ALL SELECT e,-1 FROM overlapping),
 grouped AS (SELECT t,sum(delta) AS delta FROM events GROUP BY t),
 running AS (SELECT sum(delta) OVER (ORDER BY t) AS n FROM grouped)
 SELECT coalesce(max(n),0) INTO occupied FROM running;
 IF occupied>=room_capacity THEN RAISE check_violation USING MESSAGE='Accommodation capacity exceeded'; END IF;
 RETURN new;
END $$;

-- Regression query:
WITH intervals(s,e) AS (VALUES (1,3),(3,5)), events AS (SELECT s t,1 delta FROM intervals UNION ALL SELECT e,-1 FROM intervals), grouped AS (SELECT t,sum(delta) delta FROM events GROUP BY t), running AS (SELECT sum(delta) OVER(ORDER BY t) n FROM grouped) SELECT max(n)=1 AS adjacent_pass FROM running;
