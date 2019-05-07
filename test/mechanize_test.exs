defmodule MechanizeTest do
  use ExUnit.Case
  doctest Mechanize

  test "greets the world" do
    assert Mechanize.hello() == :world
  end
end
