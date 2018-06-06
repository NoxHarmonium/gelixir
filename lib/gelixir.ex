defmodule Gelixir do
  use Application

  def start(_type, _args) do
    Gelixir.Supervisor.start_link(name: Gelixir.Supervisor)
  end
end
