defmodule Mechanizex.HTMLParser do
  alias Mechanizex.Page
  alias Mechanizex.Page.Element

  @type selector :: String.t()
  @type attribute :: atom()

  @callback search(Page.t() | list(Element.t()) | [], selector) :: list(Element.t())

  @spec parser(String.t()) :: module()
  def parser(parser_name) do
    Plugin.get(__MODULE__, parser_name)
  end
end

defprotocol Parseable do
  def parser(parseable)
  def parser_data(parseable)
  def page(parseable)
end
