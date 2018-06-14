defmodule Gelixir.Geography do
  @moduledoc """
  Helper functions for calculating geography related data.
  """

  import Float

  # Latitude: 1 deg = 110.574 km
  # Longitude: 1 deg = 111.320*cos(latitude) km
  # Approx but good enough for this use case.
  # Thanks: https://stackoverflow.com/a/1253545

  # KM
  @geo_hash_resolution 25

  @doc """
  Converts distance in KM to the equivilant distance in degrees.

  Assumes that the distance is east/west with latitude and north/south with longitude.
  """
  def km_to_lat_lng(km) do
    latitude = km / 110.574
    longitude = km / (111.320 * :math.cos(latitude))
    {latitude, longitude}
  end

  @doc """
  Converts distance in degrees to the equivilant distance in KM.

  Assumes that the distance is east/west with latitude and north/south with longitude.
  """
  def lat_lng_to_km(latitude, longitude) do
    {latitude * 110.574, longitude * 111.320 * :math.cos(latitude)}
  end

  @doc """
  Calculates a string that can be used to group up entities.

  For example, if the resolution is 25 KM, the world will be broken up into
  a grid of 25km squares. Any entity inside the same square will get the same hash.
  """
  def calculate_geohash(latitude, longitude) do
    {lat_per_unit, lng_per_unit} = km_to_lat_lng(@geo_hash_resolution)
    hash_x = floor(latitude / lat_per_unit)
    hash_y = floor(longitude / lng_per_unit)
    "#{hash_x}_#{hash_y}"
  end
end
