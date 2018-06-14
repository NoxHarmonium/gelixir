defmodule Gelixir.Types.ClientState do
  defstruct [
    :name,
    :session_started,
    :hub_coordinator_pid,
    :user_agent,
    :latitude,
    :longitude,
    :socket
  ]
end
