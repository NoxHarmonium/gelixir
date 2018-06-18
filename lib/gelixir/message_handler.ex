require Logger

defmodule Gelixir.MessageHandler do
  @moduledoc """
  Parses messages received by the Client actor and dispatches responses.
  """

  require Gelixir.Types.MessageHandlerState
  require Gelixir.Types.RegisterMessage
  require Gelixir.Types.UpdateLocationMessage
  alias Gelixir.Types.MessageHandlerState, as: MessageHandlerState
  alias Gelixir.Types.RegisterMessage, as: RegisterMessage
  alias Gelixir.Types.UpdateLocationMessage, as: UpdateLocationMessage

  use GenServer, restart: :temporary

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init({client_pid}) do
    Logger.info("Message handler started")

    with {:ok, client_responder_pid} <- Gelixir.ClientResponder.start_link({client_pid}),
         {:ok, session_manager_pid} <- Gelixir.SessionManager.start_link({}) do
      {:ok,
       %MessageHandlerState{
         client_pid: client_pid,
         client_responder_pid: client_responder_pid,
         session_manager_pid: session_manager_pid
       }}
    else
      err -> {:error, "Could not start child processes: #{inspect(err)}"}
    end
  end

  @doc """
  Takes a message/packet received from the Client and dispatches responses.
  """
  def handle_cast({:handle_message, packet}, state) do
    trimmed_packet = String.trim(packet)
    [command | data] = String.split(trimmed_packet, "|")

    new_state =
      case command do
        "REGISTER" ->
          [name, user_agent] = data
          register(%RegisterMessage{name: name, user_agent: user_agent}, state)

        "UPDATE_LOCATION" ->
          [latitude, longitude] = Enum.map(data, &String.to_float(&1))
          update_location(%UpdateLocationMessage{latitude: latitude, longitude: longitude}, state)

        _ ->
          GenServer.cast(state.client_responder_pid, {:respond, :unknown_command, command})
          state
      end

    {:noreply, new_state}
  end

  defp register(register_data, state) do
    {:ok} = GenServer.call(state.session_manager_pid, {:register, register_data.name})

    {:ok, pid} =
      Gelixir.LocationManager.start_link({state.client_responder_pid, register_data.name})

    GenServer.cast(state.client_responder_pid, {:respond, :registration_success})
    %{state | location_manager_pid: pid, session_started: true}
  end

  defp update_location(update_location_data, state) do
    %{:latitude => latitude, :longitude => longitude} = update_location_data

    case state do
      %{:session_started => false} ->
        GenServer.cast(state.client_responder_pid, {:respond, :registration_required})
        state

      _ ->
        {:ok} =
          GenServer.call(state.location_manager_pid, {:update_this_location, latitude, longitude})

        GenServer.cast(state.client_responder_pid, {:respond, :location_updated})
        state
    end
  end
end
