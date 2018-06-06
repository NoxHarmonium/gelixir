require Logger

defmodule Gelixir.ConnectionHandler do
  alias Gelixir.Types.ClientState, as: ClientState
  alias Gelixir.Types.RegisterMessage, as: RegisterMessage

  use GenServer, restart: :temporary

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(args) do
    Logger.info("Connection handler started")
    Process.flag(:trap_exit, :true)
    {:ok, %ClientState{}}
  end

  def terminate(reason, state) do
    Logger.info("Connection handler exited")
    :ok
  end

  def handle_cast({}, state) do
    {:noreply, state}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_info({:tcp, socket, packet}, state) do
    Logger.info("Incoming packet")
    {response, new_state} = handle_packet(packet, state)
    :gen_tcp.send(socket, response)
    {:noreply, new_state}
  end

  def handle_info({:tcp_closed, socket}, state) do
    Logger.info("Socket has been closed")
    {:stop, :shutdown, state}
  end

  def handle_info({:tcp_error, socket, reason}, state) do
    Logger.info("Connection closed due to #{reason}")
    {:noreply, state}
  end

  def handle_packet(packet, state) do
    trimmed_packet = String.trim(packet)
    [command | data] = String.split(trimmed_packet, "|")
    case command do
      "REGISTER" ->
        [name, user_agent] = data
        register(%RegisterMessage{name: name, user_agent: user_agent}, state)
     _ -> {"Unknown command '#{command}'\n", state}
    end
  end

  def register(register_data, state) do
    {"OK\n", %{state | name: register_data.name, user_agent: register_data.user_agent}}
  end
end
