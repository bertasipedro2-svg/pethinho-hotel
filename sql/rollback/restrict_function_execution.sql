GRANT EXECUTE ON FUNCTION public.is_staff(), public.is_admin() TO PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_profile(),
  public.validate_booking_pet(), public.enforce_booking_pet_owner(),
  public.enforce_accommodation_booking_capacity() TO PUBLIC, anon, authenticated;
