require Logger

defmodule Gelixir.LocationManager do
  import Gelixir.Geography

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init({owner, name}) do
    {:ok, %{:owner => owner, :name => name, :geo_hash => nil, :other_locations => %{}}}
  end

  def handle_cast({}, state) do
    {:noreply, state}
  end

  def handle_cast({:update_this_location, latitude, longitude}, state) do
    %{:geo_hash => previous_geohash} = state
    new_geohash = calculate_geohash(latitude, longitude)

    if previous_geohash != new_geohash do
      Logger.info(
        "New geohash (#{new_geohash}) differs from old geohash (#{previous_geohash}). Re/registering..."
      )

      Registry.unregister(Gelixir.HubRegistry, previous_geohash)
      Registry.register(Gelixir.HubRegistry, new_geohash, {})
    end

    broadcast_location(new_geohash, state.name, latitude, longitude)
    {:noreply, state}
  end

  def handle_cast({:update_other_location, pid, name, latitude, longitude}, state) do
    if pid != self() do
      Logger.info("Received update from #{name}: (lat: #{latitude} long: #{longitude})")
      GenServer.cast(state.owner, {:update, name, latitude, longitude})
      updated_locations = Map.put(state.other_locations, name, {latitude, longitude})
      {:noreply, %{state | other_locations: updated_locations}}
    else
      {:noreply, state}
    end
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def broadcast_location(geo_hash, name, latitude, longitude) do
    Registry.dispatch(Gelixir.HubRegistry, geo_hash, fn entries ->
      for {pid, _} <- entries,
          do: GenServer.cast(pid, {:update_other_location, self(), name, latitude, longitude})
    end)
  end
end
