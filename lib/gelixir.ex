defmodule Gelixir do
  @moduledoc """
  The entry point of the Gelixir application.
  """

  use Application

  @doc """
  Starts a new Gelixir application.

  Starts up all the dependencies in a supervisor to make sure they stay running.
  """
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: Gelixir.ConnectionSupervisor, strategy: :one_for_one},
      {Registry, name: Gelixir.SessionRegistry, keys: :unique},
      {Registry,
       name: Gelixir.HubRegistry, keys: :duplicate, partitions: System.schedulers_online()},
      Supervisor.child_spec(
        {Task, fn -> Gelixir.Acceptor.start_listening(8090) end},
        restart: :permanent
      )
    ]

    opts = [strategy: :one_for_one, name: Gelixir.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
