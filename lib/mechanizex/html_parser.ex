defmodule Mechanizex.HTMLParser do
  alias Mechanizex.Page
  alias Mechanizex.Page.Element

  @type selector :: String.t()
  @type attribute :: atom()

  @callback search(Page.t() | list(Element.t()) | [], selector) :: list(Element.t())
  @callback attributes(list(%Element{}), attribute) :: list(String.t())
  @callback attributes(Page.t(), selector, attribute) :: list(String.t())
  @callback text(Page.t() | list(Element.t())) :: String.t()

  @spec parser(String.t()) :: module()
  def parser(parser_name) do
    Plugin.get(__MODULE__, parser_name)
  end
end

defprotocol Parseable do
  def parser(parseable)
  def parser_data(parseable)
end
