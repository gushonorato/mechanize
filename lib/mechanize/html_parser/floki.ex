defmodule Mechanize.HTMLParser.Floki do
  @moduledoc false

  alias Mechanize.HTMLParser
  alias Mechanize.Page.{Elementable, Element}
  alias Mechanize.Page

  @behaviour Mechanize.HTMLParser

  @impl HTMLParser
  def parse_document(html_as_string) do
    {:ok, document} = Floki.parse_document(html_as_string)
    document
  end

  @impl HTMLParser
  def search(nil, _selector), do: raise(ArgumentError, "page_or_element is nil")

  @impl HTMLParser
  def search(_page_or_fragment, nil), do: raise(ArgumentError, "selector is nil")

  @impl HTMLParser
  def search(%Page{} = page, selector) do
    page.content
    |> parse_document()
    |> Floki.find(selector)
    |> Enum.map(&create_element(&1, page))
  end

  @impl HTMLParser
  def search(%Element{} = element, selector) do
    element.parser_node
    |> Floki.find(selector)
    |> Enum.map(&create_element(&1, element.page))
  end

  @impl HTMLParser
  def filter_out(nil, _selector) do
    raise ArgumentError, "page_or_elements is nil"
  end

  @impl HTMLParser
  def filter_out(_page_or_elements, nil) do
    raise ArgumentError, "selector is nil"
  end

  @impl HTMLParser
  def filter_out(%Element{} = element, selector) do
    element.parser_node
    |> List.wrap()
    |> Floki.filter_out(selector)
    |> Enum.map(&create_element(&1, element.page))
  end

  @impl HTMLParser
  def filter_out(%Page{} = page, selector) do
    page.content
    |> parse_document()
    |> Floki.filter_out(selector)
    |> Enum.map(&create_element(&1, page))
  end

  @impl HTMLParser
  def raw_html(nil) do
    raise ArgumentError, "page_or_fragment is nil"
  end

  @impl HTMLParser
  def raw_html(%Page{} = page) do
    Floki.raw_html(page.content, encode: false)
  end

  @impl HTMLParser
  def raw_html(elementable) do
    elementable
    |> Elementable.element()
    |> (fn elem -> elem.parser_node end).()
    |> Floki.raw_html(encode: false)
  end

  defp create_element({name, attributes, _} = tree, page) do
    %Element{
      name: name,
      attrs: attributes,
      parser_node: tree,
      text: Floki.text(tree),
      parser: __MODULE__,
      page: page
    }
  end
end
