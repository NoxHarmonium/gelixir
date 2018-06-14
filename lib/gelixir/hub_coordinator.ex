require Logger

defmodule Gelixir.HubCoordinator do
  import Gelixir.Geography

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init({owner}) do
    {:ok, %{:owner => owner, :geo_hash => nil, :other_locations => %{}}}
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

    broadcast_location(new_geohash, latitude, longitude)
    {:noreply, state}
  end

  def handle_cast({:update_other_location, pid, latitude, longitude}, state) do
    if pid != self() do
      Logger.info("Received update from #{inspect(pid)}: (lat: #{latitude} long: #{longitude})")
      GenServer.cast(state.owner, {:update, pid, latitude, longitude})
      updated_locations = Map.put(state.other_locations, pid, {latitude, longitude})
      {:noreply, %{state | other_locations: updated_locations}}
    else
      {:noreply, state}
    end
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def broadcast_location(geo_hash, latitude, longitude) do
    Registry.dispatch(Gelixir.HubRegistry, geo_hash, fn entries ->
      for {pid, _} <- entries,
          do: GenServer.cast(pid, {:update_other_location, self(), latitude, longitude})
    end)
  end
end
