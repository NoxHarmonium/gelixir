require Logger

defmodule Gelixir.ClientResponder do
  @moduledoc """
  Prepares the responses and forwards them onto the Client on behalf of other actors.
  """

  use GenServer, restart: :temporary

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init({client_pid}) do
    Logger.info("Connection handler started")
    {:ok, %{client_pid: client_pid}}
  end

  def handle_cast({:respond, :registration_success}, state) do
    GenServer.cast(state.client_pid, {:send_message, "OK|200|Registered\n"})
    {:noreply, state}
  end

  def handle_cast({:respond, :registration_required}, state) do
    GenServer.cast(state.client_pid, {:send_message, "FAIL|400|Registration Required\n"})
    {:noreply, state}
  end

  def handle_cast({:respond, :location_updated}, state) do
    GenServer.cast(state.client_pid, {:send_message, "OK|200|Location Updated\n"})
    {:noreply, state}
  end

  def handle_cast({:respond, :update, name, latitude, longitude}, state) do
    GenServer.cast(state.client_pid, {:send_message, "UPDATE|#{name}|#{latitude}|#{longitude}\n"})
    {:noreply, state}
  end

  def handle_cast({:respond, :unknown_command, command}, state) do
    GenServer.cast(state.client_pid, {:send_message, "Unknown command '#{command}'\n"})
    {:noreply, state}
  end
end
