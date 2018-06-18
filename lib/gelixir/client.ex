require Logger

defmodule Gelixir.Client do
  @moduledoc """
  Manages messages sent via a tcp client.
  """

  require Gelixir.Types.ClientState
  alias Gelixir.Types.ClientState, as: ClientState

  use GenServer, restart: :temporary

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(_) do
    Logger.debug("Starting client...")

    with {:ok, message_handler_pid} <- Gelixir.MessageHandler.start_link({self()}) do
      {:ok, %ClientState{message_handler_pid: message_handler_pid}}
    else
      err -> {:error, "Could not start child processes: #{inspect(err)}"}
    end
  end

  @doc """
  Updates the TCP client with the location of another Client.

  This should be called by LocationManager actors.
  """
  def handle_cast({:send_message, message}, state) do
    :gen_tcp.send(state.socket, message)
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
  def handle_info({:tcp, _, packet}, state) do
    GenServer.cast(state.message_handler_pid, {:handle_message, packet})
    {:noreply, state}
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
end
