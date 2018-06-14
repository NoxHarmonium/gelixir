defmodule Gelixir.Geography do
  import Float

  # Latitude: 1 deg = 110.574 km
  # Longitude: 1 deg = 111.320*cos(latitude) km
  # Approx but good enough for this use case.
  # Thanks: https://stackoverflow.com/a/1253545

  # KM
  @geo_hash_resolution 25

  def km_to_lat_lng(km) do
    latitude = km / 110.574
    longitude = km / (111.320 * :math.cos(latitude))
    {latitude, longitude}
  end

  def lat_lng_to_km(latitude, longitude) do
    {latitude * 110.574, longitude * 111.320 * :math.cos(latitude)}
  end

  def calculate_geohash(latitude, longitude) do
    {lat_per_unit, lng_per_unit} = km_to_lat_lng(@geo_hash_resolution)
    hash_x = floor(latitude / lat_per_unit)
    hash_y = floor(longitude / lng_per_unit)
    "#{hash_x}_#{hash_y}"
  end
end
