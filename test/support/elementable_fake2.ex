defmodule Mechanize.Test.Support.ElementableFake2 do
  @derive [Mechanize.Page.Elementable]
  defstruct [:element]
end
