defmodule LabexTest do
  use ExUnit.Case
  doctest Labex

  test "greets the world" do
    assert Labex.hello() == :world
  end
end
