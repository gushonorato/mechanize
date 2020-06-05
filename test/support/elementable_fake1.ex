defmodule Mechanize.Test.Support.ElementableFake1 do
  @derive [Mechanize.Page.Elementable]
  defstruct [:element]
end
