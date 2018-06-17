require Logger

defmodule Gelixir.MessageHandler do
  @moduledoc """
  Manages messages sent via a tcp client.
  """

  require Gelixir.Types.MessageHandlerState
  require Gelixir.Types.RegisterMessage
  require Gelixir.Types.UpdateLocationMessage
  alias Gelixir.Types.MessageHandlerState, as: MessageHandlerState
  alias Gelixir.Types.RegisterMessage, as: RegisterMessage
  alias Gelixir.Types.UpdateLocationMessage, as: UpdateLocationMessage

  use GenServer, restart: :temporary

  # Command strings
  @register "REGISTER"
  @update_location "UPDATE_LOCATION"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init({client_pid, client_responder_pid}) do
    Logger.info("Connection handler started")

    {:ok,
     %MessageHandlerState{client_pid: client_pid, client_responder_pid: client_responder_pid}}
  end

  def handle_cast({:handle_message, packet}, state) do
    trimmed_packet = String.trim(packet)
    [command | data] = String.split(trimmed_packet, "|")

    new_state =
      case command do
        @register ->
          [name, user_agent] = data
          register(%RegisterMessage{name: name, user_agent: user_agent}, state)

        @update_location ->
          [latitude, longitude] = Enum.map(data, &String.to_float(&1))
          update_location(%UpdateLocationMessage{latitude: latitude, longitude: longitude}, state)

        _ ->
          GenServer.cast(state.client_responder_pid, {:respond, :unknown_command, command})
          state
      end

    {:noreply, new_state}
  end

  defp register(register_data, state) do
    # Sessions must be unique, so kill the existing session
    case Registry.lookup(Gelixir.SessionRegistry, register_data.name) do
      [existing_client] -> GenServer.call(existing_client, :stop)
      [] -> {}
    end

    Registry.register(Gelixir.SessionRegistry, register_data.name, {})
    Logger.info("Registered session for #{register_data.name}")

    {:ok, pid} =
      Gelixir.LocationManager.start_link({state.client_responder_pid, register_data.name})

    GenServer.cast(state.client_responder_pid, {:respond, :registration_success})
    %{state | location_manager_pid: pid}
  end

  defp update_location(update_location_data, state) do
    %{:latitude => latitude, :longitude => longitude} = update_location_data

    case state do
      %{:session_started => false} ->
        GenServer.cast(state.client_responder_pid, {:respond, :registration_required})
        state

      _ ->
        %{:location_manager_pid => location_manager_pid} = state
        GenServer.cast(location_manager_pid, {:update_this_location, latitude, longitude})
        GenServer.cast(state.client_responder_pid, {:respond, :location_updated})
        state
    end
  end
end
