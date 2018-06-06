defmodule Gelixir.Types.RegisterMessage do
  defmacro command_tag do
    quote do: "REGISTER"
  end
  defstruct [:name, :user_agent]
end
