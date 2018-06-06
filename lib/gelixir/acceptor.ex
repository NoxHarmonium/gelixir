require Logger

defmodule Gelixir.Acceptor do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(_opts) do
    accept(8090)
    {:ok, %{}}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: true` - packets sent from the peer are delivered as messages
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, socket} =
      case :gen_tcp.listen(port, [:binary, packet: :line, active: true, reuseaddr: true]) do
        {:ok, socket} ->
          Logger.info("Accepting connections on port #{port}")
          loop_acceptor(socket)

        {:error, reason} ->
          Logger.error("Could not listen: #{reason}")
      end
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} =
      DynamicSupervisor.start_child(Gelixir.ConnectionSupervisor, Gelixir.ConnectionHandler)

    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end
end
