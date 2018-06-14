defmodule Gelixir.Types.ClientState do
  defstruct [
    :name,
    :session_started,
    :location_manager_pid,
    :user_agent,
    :latitude,
    :longitude,
    :socket
  ]
end
