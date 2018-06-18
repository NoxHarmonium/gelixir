require Logger

defmodule Gelixir.SessionManager do
  @moduledoc """
  Manages sessions so that a Client can't be connected twice.
  """

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init({}) do
    Logger.info("Session manager started")
    {:ok, {}}
  end

  def handle_call({:register, name}, _, state) do
    # Sessions must be unique, so kill the existing session
    case Registry.lookup(Gelixir.SessionRegistry, name) do
      [existing_client] -> GenServer.call(existing_client, :stop)
      [] -> {}
    end

    Registry.register(Gelixir.SessionRegistry, name, {})
    {:reply, {:ok}, state}
  end
end
