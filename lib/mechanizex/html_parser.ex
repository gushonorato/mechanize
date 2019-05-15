defmodule Mechanizex.HTMLParser do
  alias Mechanizex.Page

  defmacro __using__(_) do
    quote do
      @behaviour Mechanizex.HTMLParser
    end
  end

  @callback find(Page.t(), String.t()) :: list()
  @callback attribute(map(), String.t() | atom()) :: list()
  @callback text(map() | Page.t()) :: String.t()

  @spec parser(String.t()) :: module()
  def parser(parser_name) do
    Plugin.get(__MODULE__, parser_name)
  end
end
