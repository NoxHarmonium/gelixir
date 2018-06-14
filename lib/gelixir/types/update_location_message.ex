defmodule Gelixir.Types.UpdateLocationMessage do
  defmacro command_tag do
    quote do: "UPDATE_LOCATION"
  end

  defstruct [:latitude, :longitude]
end
