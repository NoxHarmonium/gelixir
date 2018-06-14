require Logger

defmodule Gelixir.Client do
  @moduledoc """
  Manages messages sent via a tcp client.
  """

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
    {:ok, %ClientState{}}
  end

  @doc """
  Updates the TCP client with the location of another Client.

  This should be called by LocationManager actors.
  """
  def handle_cast({:update, name, latitude, longitude}, state) do
    :gen_tcp.send(state.socket, "UPDATE|#{name}|#{latitude}|#{longitude}\n")
    {:noreply, state}
  end

  @doc """
  Stops this actor.

  Cleans up associated resources such as sockets.
  """
  def handle_call(:stop, _from, state) do
    {:stop, :normal, state}
  end

  @doc """
  Called by the parent Acceptor to give this actor a reference to the TCP socket.

  This is needed to send messages that are not in response to another message.
  E.g. Outside of handle_info/2.
  """
  def handle_call({:set_socket, socket}, _, state) do
    {:reply, :ok, %{state | :socket => socket}}
  end

  @doc """
  Handles a new message from the TCP client.

  It should respond in a timely manner with long running tasks 
  handed to other actors such as LocationManager.
  """
  def handle_info({:tcp, socket, packet}, state) do
    {response, new_state} = handle_packet(packet, state)
    :gen_tcp.send(socket, response)
    {:noreply, new_state}
  end

  @doc """
  Handles the TCP connection closing.
  """
  def handle_info({:tcp_closed, _}, state) do
    Logger.info("Socket has been closed")
    {:stop, :shutdown, state}
  end

  @doc """
  Handles a TCP error.
  """
  def handle_info({:tcp_error, _, reason}, state) do
    Logger.info("Connection closed due to #{reason}")
    {:noreply, state}
  end

  defp handle_packet(packet, state) do
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

  defp register(register_data, state) do
    # Sessions must be unique, so kill the existing session
    case Registry.lookup(Gelixir.SessionRegistry, register_data.name) do
      [existing_connection_handler] -> GenServer.call(existing_connection_handler, :stop)
      [] -> {}
    end

    Registry.register(Gelixir.SessionRegistry, register_data.name, {})
    Logger.info("Registered session for #{register_data.name}")

    {:ok, pid} = Gelixir.LocationManager.start_link({self(), register_data.name})

    {"OK|200|Registered\n",
     %{
       state
       | name: register_data.name,
         user_agent: register_data.user_agent,
         session_started: true,
         location_manager_pid: pid
     }}
  end

  defp update_location(update_location_data, state) do
    %{:latitude => latitude, :longitude => longitude} = update_location_data

    case state do
      %{:session_started => false} ->
        {"FAIL|400|Registration Required\n", state}

      _ ->
        %{:location_manager_pid => location_manager_pid} = state
        GenServer.cast(location_manager_pid, {:update_this_location, latitude, longitude})

        {"OK|200|Location Updated\n",
         %{
           state
           | latitude: latitude,
             longitude: longitude
         }}
    end
  end
end
