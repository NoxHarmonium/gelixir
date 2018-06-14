require Logger

defmodule Gelixir.Acceptor do
  def start_listening(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: true` - packets sent from the peer are delivered as messages
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    case :gen_tcp.listen(port, [:binary, packet: :line, active: true, reuseaddr: true]) do
      {:ok, listen_socket} ->
        Logger.info("Accepting connections on port #{port}")
        loop_acceptor(listen_socket)

      {:error, reason} ->
        Logger.error("Could not listen: #{reason}")
    end
  end

  defp loop_acceptor(listen_socket) do
    {:ok, socket} = :gen_tcp.accept(listen_socket)

    {:ok, pid} = DynamicSupervisor.start_child(Gelixir.ConnectionSupervisor, Gelixir.Client)

    GenServer.call(pid, {:set_socket, socket})
    :ok = :gen_tcp.controlling_process(socket, pid)
    loop_acceptor(listen_socket)
  end
end
