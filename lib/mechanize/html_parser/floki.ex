defmodule Mechanize.HTMLParser.Floki do
  @moduledoc false

  alias Mechanize.HTMLParser
  alias Mechanize.Page.{Elementable, Element}
  alias Mechanize.Page

  @behaviour Mechanize.HTMLParser

  @impl HTMLParser
  def search(nil, _selector), do: raise(ArgumentError, "page_or_elements is nil")

  @impl HTMLParser
  def search(_page_or_elements, nil), do: raise(ArgumentError, "selector is nil")

  @impl HTMLParser
  def search([], _selector), do: []

  @impl HTMLParser
  def search(%Page{} = page, selector) do
    page.content
    |> Floki.find(selector)
    |> Enum.map(&create_element(&1, page))
  end

  @impl HTMLParser
  def search(elements, selector) do
    check_elements_from_same_page(elements)

    elements
    |> Enum.map(& &1.parser_data)
    |> Floki.find(selector)
    |> Enum.map(&create_element(&1, List.first(elements).page))
  end

  @impl HTMLParser
  def filter(nil, _selector) do
    raise ArgumentError, "page_or_elements is nil"
  end

  @impl HTMLParser
  def filter(_page_or_elements, nil) do
    raise ArgumentError, "selector is nil"
  end

  @impl HTMLParser
  def filter([], _selector), do: []

  @impl HTMLParser
  def filter(elements, selector) when is_list(elements) do
    check_elements_from_same_page(elements)

    elements
    |> Enum.map(& &1.parser_data)
    |> Floki.filter_out(selector)
    |> Enum.map(&create_element(&1, List.first(elements).page))
  end

  @impl HTMLParser
  def filter(%Page{} = page, selector) do
    page.content
    |> Floki.filter_out(selector)
    |> List.wrap()
    |> Enum.map(&create_element(&1, page))
  end

  @impl HTMLParser
  def raw_html(nil) do
    raise ArgumentError, "page_or_elements is nil"
  end

  @impl HTMLParser
  def raw_html(%Page{} = page) do
    Floki.raw_html(page.content, encode: false)
  end

  @impl HTMLParser
  def raw_html(elementable) do
    elementable
    |> Elementable.element()
    |> (fn elem -> elem.parser_data end).()
    |> Floki.raw_html(encode: false)
  end

  defp check_elements_from_same_page(elements) do
    Enum.reduce(elements, List.first(elements).page, fn e, page ->
      unless page == e.page, do: raise(ArgumentError, "Elements are not from the same page")
    end)
  end

  defp create_element({name, attributes, _} = tree, page) do
    %Element{
      name: name,
      attrs: attributes,
      parser_data: tree,
      text: Floki.text(tree),
      parser: __MODULE__,
      page: page
    }
  end
end
