defmodule Gelixir.Types.MessageHandlerState do
  defstruct [
    :name,
    :session_started,
    :client_pid,
    :client_responder_pid,
    :location_manager_pid,
    :user_agent
  ]
end
