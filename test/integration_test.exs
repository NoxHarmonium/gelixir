require Logger

defmodule IntegrationTest do
  use ExUnit.Case

  setup do
    Application.stop(:gelixir)
    :ok = Application.start(:gelixir)
  end

  setup do
    opts = [:binary, packet: :line, active: false]
    {:ok, socket_a} = :gen_tcp.connect('localhost', 8090, opts)
    {:ok, socket_b} = :gen_tcp.connect('localhost', 8090, opts)
    %{socket_a: socket_a, socket_b: socket_b}
  end

  test "server interaction", %{socket_a: socket_a, socket_b: socket_b} do
    # Register and setup initial location
    assert send_and_recv(socket_a, "REGISTER|socket_a|exunit\n") == "OK|200|Registered\n"
    assert send_and_recv(socket_b, "REGISTER|socket_b|exunit\n") == "OK|200|Registered\n"
    assert send_and_recv(socket_a, "UPDATE_LOCATION|10.2|10.2\n") == "OK|200|Location Updated\n"

    assert send_and_recv(socket_b, "UPDATE_LOCATION|10.2|10.2\n") == "OK|200|Location Updated\n"
    assert recv(socket_a) == "UPDATE|socket_b|10.2|10.2\n"

    assert send_and_recv(socket_a, "UPDATE_LOCATION|10.21|10.21\n") == "OK|200|Location Updated\n"
    assert recv(socket_b) == "UPDATE|socket_a|10.21|10.21\n"
  end

  defp recv(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0, 1000)
    data
  end

  defp send_and_recv(socket, command) do
    :ok = :gen_tcp.send(socket, command)
    recv(socket)
  end
end
