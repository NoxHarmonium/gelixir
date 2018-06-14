require Logger

defmodule Gelixir.ConnectionHandler do
  require Gelixir.Types.ClientState
  require Gelixir.Types.RegisterMessage
  require Gelixir.Types.UpdateLocationMessage
  alias Gelixir.Types.ClientState, as: ClientState
  alias Gelixir.Types.RegisterMessage, as: RegisterMessage
  alias Gelixir.Types.UpdateLocationMessage, as: UpdateLocationMessage

  use GenServer, restart: :temporary

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(_) do
    Logger.info("Connection handler started")
    {:ok, pid} = Gelixir.HubCoordinator.start_link({self()})
    {:ok, %ClientState{:hub_coordinator_pid => pid}}
  end

  def handle_cast({:update, pid, latitude, longitude}, state) do
    :gen_tcp.send(state.socket, "UPDATE|#{inspect(pid)}|#{latitude}|#{longitude}\n")
    {:noreply, state}
  end

  def handle_cast({}, state) do
    {:noreply, state}
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  def handle_call({:set_socket, socket}, _, state) do
    {:reply, :ok, %{state | :socket => socket}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_info({:tcp, socket, packet}, state) do
    {response, new_state} = handle_packet(packet, state)
    :gen_tcp.send(socket, response)
    {:noreply, new_state}
  end

  def handle_info({:tcp_closed, _}, state) do
    Logger.info("Socket has been closed")
    {:stop, :shutdown, state}
  end

  def handle_info({:tcp_error, _, reason}, state) do
    Logger.info("Connection closed due to #{reason}")
    {:noreply, state}
  end

  def handle_packet(packet, state) do
    trimmed_packet = String.trim(packet)
    [command | data] = String.split(trimmed_packet, "|")

    case command do
      RegisterMessage.command_tag() ->
        [name, user_agent] = data
        register(%RegisterMessage{name: name, user_agent: user_agent}, state)

      UpdateLocationMessage.command_tag() ->
        [latitude, longitude] = Enum.map(data, &String.to_float(&1))
        update_location(%UpdateLocationMessage{latitude: latitude, longitude: longitude}, state)

      _ ->
        {"Unknown command '#{command}'\n", state}
    end
  end

  def register(register_data, state) do
    # Sessions must be unique, so kill the existing session
    case Registry.lookup(Gelixir.SessionRegistry, register_data.name) do
      [existing_connection_handler] -> GenServer.call(existing_connection_handler, :stop)
      [] -> {}
    end

    Registry.register(Gelixir.SessionRegistry, register_data.name, {})
    Logger.info("Registered session for #{register_data.name}")

    {"OK|200|Registered\n",
     %{
       state
       | name: register_data.name,
         user_agent: register_data.user_agent,
         session_started: true
     }}
  end

  def update_location(update_location_data, state) do
    %{:hub_coordinator_pid => hub_coordinator_pid} = state
    %{:latitude => latitude, :longitude => longitude} = update_location_data

    case state do
      %{:session_started => false} ->
        {"FAIL|400|Registration Required\n", state}

      _ ->
        GenServer.cast(hub_coordinator_pid, {:update_this_location, latitude, longitude})

        {"OK|200|Location Updated\n",
         %{
           state
           | latitude: latitude,
             longitude: longitude
         }}
    end
  end
end
