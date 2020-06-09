defmodule Mechanize.HTMLParser do
  @moduledoc false

  alias Mechanize.Page
  alias Mechanize.Page.Element

  @type selector :: String.t()
  @type attribute :: atom()
  @type parser_node :: any()

  @callback parse_document(String.t()) :: list(parser_node())

  @callback search(Page.t() | Element.t(), selector) :: list(Element.t())
  @callback filter(Page.t() | Element.t(), selector) :: list(Element.t())
  @callback raw_html(Page.t() | Element.t()) :: String.t()
end
