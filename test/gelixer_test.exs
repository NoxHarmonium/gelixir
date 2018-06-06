defmodule GelixerTest do
  use ExUnit.Case
  doctest Gelixer

  test "greets the world" do
    assert Gelixer.hello() == :world
  end
end
