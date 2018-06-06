defmodule Gelixir.Supervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg)
  end

  def init(arg) do
    children = [
      {DynamicSupervisor, name: Gelixir.ConnectionSupervisor, strategy: :one_for_one},
      {Gelixir.Acceptor, name: Gelixir.Acceptor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
